//
//  AuraApp.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import FirebaseCore

@main
struct AuraApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // 初始化 Firebase
        FirebaseApp.configure()
        print("🔥 Firebase 初始化完成")
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
