//
//  AuthView.swift
//  Aura
//
//  登录/注册界面
//

import SwiftUI

extension Color {
    static let auraGreenDark = Color(red: 0.12, green: 0.55, blue: 0.28)
}

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isLoginMode = true
    @State private var showingForgotPassword = false

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.auraGreen.opacity(0.85), Color.auraGreenDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        logoSection
                        formSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordSheet(email: $email, onDismiss: { showingForgotPassword = false })
                    .environmentObject(viewModel)
            }
        }
    }

    private var logoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
                Text("Au")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("ra")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 60)
            Text(isLoginMode ? "Welcome Back" : "Create Account")
                .font(.title3)
                .foregroundColor(.white.opacity(0.95))
        }
    }

    private var formSection: some View {
        VStack(spacing: 18) {
            if !isLoginMode {
                AuthTextField(
                    icon: "person.fill",
                    placeholder: "Display Name (optional)",
                    text: $displayName
                )
            }

            AuthTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            AuthSecureField(placeholder: "Password (min 6 chars)", text: $password)

            if !isLoginMode {
                AuthSecureField(placeholder: "Confirm Password", text: $confirmPassword)
            }

            if let msg = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(msg)
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            }

            if let msg = viewModel.successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text(msg)
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            }

            Button(action: handleAuth) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.auraGreen)
                    } else {
                        Text(isLoginMode ? "Sign In" : "Sign Up")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.auraGreen)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            if isLoginMode {
                Button {
                    showingForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isLoginMode.toggle()
                    viewModel.clearMessages()
                    email = ""
                    password = ""
                    confirmPassword = ""
                    displayName = ""
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                        .foregroundColor(.white.opacity(0.85))
                    Text(isLoginMode ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .font(.callout)
            }
        }
        .padding(.top, 8)
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
                viewModel.errorMessage = "Passwords do not match"
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
            viewModel.errorMessage = "Please enter your email address first"
            return
        }
        
        Task {
            await viewModel.resetPassword(email: email)
        }
    }
}

// MARK: - 表单组件

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, alignment: .center)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(14)
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, alignment: .center)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            Button { isSecure.toggle() } label: {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.15))
        .cornerRadius(14)
    }
}

// MARK: - 忘记密码

struct ForgotPasswordSheet: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    let onDismiss: () -> Void

    @State private var inputEmail = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter the email you used to register and we'll send a password reset link.")
                    .font(.subheadline)
                    .foregroundColor(Color.auraGrayDark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                AuthTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $inputEmail,
                    keyboardType: .emailAddress
                )
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .onAppear { inputEmail = email }

                if let msg = viewModel.errorMessage {
                    Text(msg).font(.caption).foregroundColor(Color.auraRed)
                }
                if let msg = viewModel.successMessage {
                    Text(msg).font(.caption).foregroundColor(Color.auraGreen)
                }

                Button {
                    Task {
                        await viewModel.resetPassword(email: inputEmail)
                        if viewModel.successMessage != nil {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            onDismiss()
                            dismiss()
                        }
                    }
                } label: {
                    Text("Send Reset Email")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.auraGreen)
                        .cornerRadius(14)
                }
                .disabled(viewModel.isLoading || inputEmail.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .background(Color(white: 0.97))
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        viewModel.clearMessages()
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(Color.auraGreen)
                }
            }
        }
    }
}

// 保留旧名称以兼容可能的引用
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var body: some View {
        AuthTextField(icon: icon, placeholder: placeholder, text: $text, keyboardType: keyboardType)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var body: some View {
        AuthSecureField(placeholder: placeholder, text: $text)
    }
}

// MARK: - 预览

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
