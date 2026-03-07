//
//  ContentView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var healthDataManager: HealthDataManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            NutritionAnalysisView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Nutrition")
                }
                .tag(1)
            
            FitnessTrackerView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Activity")
                }
                .tag(2)
            
            AIAdviceView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("AI Advice")
                }
                .tag(3)
        }
        .tint(Color.auraGreen)
        .task {
            await healthDataManager.refreshIfNeeded()
        }
        .onAppear {
            let tabAppearance = UITabBarAppearance()
            tabAppearance.configureWithOpaqueBackground()
            tabAppearance.backgroundColor = UIColor.white

            let selectedColor = UIColor(red: 0.12, green: 0.40, blue: 0.31, alpha: 1)
            let normalColor = UIColor(red: 0.70, green: 0.68, blue: 0.56, alpha: 1)

            tabAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
            tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
            tabAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
            tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            tabAppearance.selectionIndicatorImage = UIImage()

            UITabBar.appearance().standardAppearance = tabAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthDataManager())
}
