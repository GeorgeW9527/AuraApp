//
//  AuthViewModel.swift
//  Aura
//
//  用户认证 ViewModel
//

import Foundation
import SwiftUI
import CloudBase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: TCloudBaseUser?
    @Published var userProfile: UserProfile?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let cloudBaseManager = CloudBaseManager.shared
    
    init() {
        // 监听认证状态
        self.isAuthenticated = cloudBaseManager.isAuthenticated
        self.currentUser = cloudBaseManager.currentUser
        
        // 订阅腾讯云认证状态变化
        cloudBaseManager.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        cloudBaseManager.$currentUser
            .assign(to: &$currentUser)
        
        // 如果已登录，加载用户配置
        if isAuthenticated {
            Task {
                await loadUserProfile()
            }
        }
    }
    
    // MARK: - 注册
    
    func signUp(email: String, password: String, displayName: String?) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "请填写邮箱和密码"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "密码至少需要6位"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await cloudBaseManager.signUp(email: email, password: password)
            
            // 创建用户配置
            let profile = UserProfile(
                userId: user.uid ?? "",
                displayName: displayName,
                email: email
            )
            
            _ = try await cloudBaseManager.saveData(
                collection: "userProfiles",
                data: profile
            )
            
            self.userProfile = profile
            successMessage = "注册成功！"
            print("✅ 用户注册成功: \(email)")
            
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ 注册失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 登录
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "请填写邮箱和密码"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await cloudBaseManager.signIn(email: email, password: password)
            await loadUserProfile()
            successMessage = "登录成功！"
            print("✅ 用户登录成功: \(email)")
            
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ 登录失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 退出登录
    
    func signOut() {
        do {
            try cloudBaseManager.signOut()
            userProfile = nil
            successMessage = "已退出登录"
            print("✅ 用户退出登录")
        } catch {
            errorMessage = "退出登录失败: \(error.localizedDescription)"
            print("❌ 退出登录失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 重置密码
    
    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "请输入邮箱地址"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await cloudBaseManager.resetPassword(email: email)
            successMessage = "密码重置邮件已发送，请查收邮箱"
            print("✅ 密码重置邮件已发送: \(email)")
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ 密码重置失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 加载用户配置
    
    func loadUserProfile() async {
        guard let userId = currentUser?.uid else { return }
        
        do {
            let profiles: [UserProfile] = try await cloudBaseManager.fetchData(
                collection: "userProfiles",
                as: UserProfile.self
            )
            self.userProfile = profiles.first
            print("✅ 用户配置加载成功")
        } catch {
            print("⚠️ 用户配置加载失败: \(error.localizedDescription)")
            // 如果配置不存在，创建默认配置
            let profile = UserProfile(userId: userId, email: "")
            self.userProfile = profile
            
            Task {
                try? await cloudBaseManager.saveData(
                    collection: "userProfiles",
                    data: profile
                )
            }
        }
    }
    
    // MARK: - 更新用户配置
    
    func updateUserProfile(_ profile: UserProfile) async {
        guard let userId = currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedProfile = profile
            updatedProfile.updatedAt = Date()
            
            _ = try await cloudBaseManager.saveData(
                collection: "userProfiles",
                data: updatedProfile
            )
            
            self.userProfile = updatedProfile
            successMessage = "配置更新成功"
            print("✅ 用户配置更新成功")
        } catch {
            errorMessage = "配置更新失败: \(error.localizedDescription)"
            print("❌ 配置更新失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - 错误处理
    
    private func handleAuthError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription
        
        // 根据错误信息返回友好提示
        if errorMessage.contains("email") || errorMessage.contains("邮箱") {
            if errorMessage.contains("exist") || errorMessage.contains("已存在") {
                return "该邮箱已被注册"
            } else if errorMessage.contains("invalid") || errorMessage.contains("无效") {
                return "邮箱格式不正确"
            }
        }
        
        if errorMessage.contains("password") || errorMessage.contains("密码") {
            if errorMessage.contains("weak") || errorMessage.contains("弱") {
                return "密码强度太弱"
            } else if errorMessage.contains("wrong") || errorMessage.contains("错误") {
                return "密码错误"
            }
        }
        
        if errorMessage.contains("user") || errorMessage.contains("用户") {
            if errorMessage.contains("not found") || errorMessage.contains("不存在") {
                return "用户不存在"
            }
        }
        
        if errorMessage.contains("network") || errorMessage.contains("网络") {
            return "网络连接失败"
        }
        
        return errorMessage
    }
    
    // MARK: - 清除消息
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
