//
//  AuthViewModel.swift
//  Aura
//
//  用户认证 ViewModel
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // 同步读取已保存的登录状态
        self.isAuthenticated = firebaseManager.isAuthenticated
        print("🔐 AuthViewModel init: isAuthenticated = \(isAuthenticated)")
        
        // 如果已登录，加载用户配置
        if isAuthenticated {
            Task {
                await loadUserProfile()
            }
        }
        
        // 监听 Firebase 认证状态异步变化
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                let authenticated = user != nil
                if self.isAuthenticated != authenticated {
                    self.isAuthenticated = authenticated
                    print("🔐 AuthViewModel 状态更新: \(authenticated)")
                    if authenticated {
                        await self.loadUserProfile()
                    } else {
                        self.userProfile = nil
                    }
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    var currentUser: FirebaseAuth.User? {
        firebaseManager.currentUser
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
            let user = try await firebaseManager.signUp(email: email, password: password)
            
            // 创建用户配置
            let profile = UserProfile(
                userId: user.uid,
                displayName: displayName,
                email: email
            )
            
            try await firebaseManager.saveData(
                collection: "userProfiles",
                documentId: user.uid,
                data: profile
            )
            
            self.userProfile = profile
            self.isAuthenticated = true
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
            let user = try await firebaseManager.signIn(email: email, password: password)
            await loadUserProfile()
            self.isAuthenticated = true
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
            try firebaseManager.signOut()
            self.isAuthenticated = false
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
            try await firebaseManager.resetPassword(email: email)
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
            let profile = try await firebaseManager.fetchData(
                collection: "userProfiles",
                documentId: userId,
                as: UserProfile.self
            )
            self.userProfile = profile
            print("✅ 用户配置加载成功: \(profile.displayName ?? "无昵称")")
        } catch let error as NSError {
            print("⚠️ 用户配置加载失败: \(error.localizedDescription)")
            
            // 只有当错误明确是"数据不存在"（首次注册）时才创建默认配置
            // 网络超时/连接失败时不覆盖，保留本地已有数据
            let isDataNotFound = error.localizedDescription.contains("数据不存在")
            
            if isDataNotFound, self.userProfile == nil {
                print("📝 首次使用，创建默认用户配置")
                if let email = currentUser?.email {
                    let profile = UserProfile(userId: userId, email: email)
                    self.userProfile = profile
                    
                    Task {
                        try? await firebaseManager.saveData(
                            collection: "userProfiles",
                            documentId: userId,
                            data: profile
                        )
                    }
                }
            } else {
                print("⚠️ 网络问题导致加载失败，保留现有数据不覆盖")
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
            
            try await firebaseManager.saveData(
                collection: "userProfiles",
                documentId: userId,
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
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "该邮箱已被注册"
        case AuthErrorCode.invalidEmail.rawValue:
            return "邮箱格式不正确"
        case AuthErrorCode.weakPassword.rawValue:
            return "密码强度太弱"
        case AuthErrorCode.wrongPassword.rawValue:
            return "密码错误"
        case AuthErrorCode.userNotFound.rawValue:
            return "用户不存在"
        case AuthErrorCode.networkError.rawValue:
            return "网络连接失败"
        case AuthErrorCode.tooManyRequests.rawValue:
            return "请求过于频繁，请稍后再试"
        default:
            return error.localizedDescription
        }
    }
    
    // MARK: - 清除消息
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
