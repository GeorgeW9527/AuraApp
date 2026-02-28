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
    }
}

#Preview {
    ContentView()
}
