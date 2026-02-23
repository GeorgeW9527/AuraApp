//
//  AuraApp.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import Combine
import FirebaseCore

@main
struct AuraApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // 启动时打印本地存储状态（调试用）
        LocalStorageManager.shared.debugPrintStatus()
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
