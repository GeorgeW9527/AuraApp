//
//  AuthView.swift
//  Aura
//
//  登录/注册界面
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isLoginMode = true
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo 和标题
                        VStack(spacing: 10) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            
                            Text("Aura")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(isLoginMode ? "欢迎回来" : "创建账号")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 50)
                        
                        // 表单
                        VStack(spacing: 20) {
                            // 显示名称（仅注册时）
                            if !isLoginMode {
                                CustomTextField(
                                    icon: "person.fill",
                                    placeholder: "昵称（可选）",
                                    text: $displayName
                                )
                            }
                            
                            // 邮箱
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "邮箱",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            .textInputAutocapitalization(.never)
                            
                            // 密码
                            CustomSecureField(
                                icon: "lock.fill",
                                placeholder: "密码",
                                text: $password
                            )
                            
                            // 确认密码（仅注册时）
                            if !isLoginMode {
                                CustomSecureField(
                                    icon: "lock.fill",
                                    placeholder: "确认密码",
                                    text: $confirmPassword
                                )
                            }
                            
                            // 错误消息
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            // 成功消息
                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal)
                            }
                            
                            // 登录/注册按钮
                            Button(action: handleAuth) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.blue)
                                    } else {
                                        Text(isLoginMode ? "登录" : "注册")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading)
                            
                            // 忘记密码（仅登录时）
                            if isLoginMode {
                                Button("忘记密码？") {
                                    handleForgotPassword()
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                            }
                            
                            // 切换登录/注册
                            Button(action: {
                                withAnimation {
                                    isLoginMode.toggle()
                                    viewModel.clearMessages()
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Text(isLoginMode ? "还没有账号？" : "已有账号？")
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(isLoginMode ? "立即注册" : "立即登录")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .font(.callout)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 处理认证
    
    private func handleAuth() {
        viewModel.clearMessages()
        
        if isLoginMode {
            // 登录
            Task {
                await viewModel.signIn(email: email, password: password)
            }
        } else {
            // 注册
            guard password == confirmPassword else {
                viewModel.errorMessage = "两次密码输入不一致"
                return
            }
            
            Task {
                await viewModel.signUp(
                    email: email,
                    password: password,
                    displayName: displayName.isEmpty ? nil : displayName
                )
            }
        }
    }
    
    // MARK: - 忘记密码
    
    private func handleForgotPassword() {
        guard !email.isEmpty else {
            viewModel.errorMessage = "请先输入邮箱地址"
            return
        }
        
        Task {
            await viewModel.resetPassword(email: email)
        }
    }
}

// MARK: - 自定义文本框

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
    }
}

// MARK: - 预览

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
