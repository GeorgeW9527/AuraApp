//
//  AuraApp.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // 腾讯云 CloudBase 会在 CloudBaseManager 初始化时自动配置
        // 无需在这里手动初始化
        print("☁️ 应用启动，腾讯云 CloudBase 已就绪")
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
