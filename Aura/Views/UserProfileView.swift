//
//  UserProfileView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var userName = "健康达人"
    @State private var userEmail = "user@aura.com"
    @State private var height = 175
    @State private var weight = 70
    @State private var age = 28
    @State private var gender = "男"
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
    var bmi: Double {
        let heightInMeters = Double(height) / 100.0
        return Double(weight) / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "偏瘦"
        case 18.5..<24: return "正常"
        case 24..<28: return "偏胖"
        default: return "肥胖"
        }
    }
    
    var bmiColor: Color {
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<24: return .green
        case 24..<28: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Text(String(userName.prefix(1)))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Text("编辑资料")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.top)
                    
                    // Health Stats
                    VStack(alignment: .leading, spacing: 15) {
                        Text("健康数据")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            HealthStatCard(title: "身高", value: "\(height)", unit: "cm", icon: "ruler", color: .blue)
                            HealthStatCard(title: "体重", value: "\(weight)", unit: "kg", icon: "scalemass", color: .green)
                            HealthStatCard(title: "年龄", value: "\(age)", unit: "岁", icon: "calendar", color: .orange)
                            HealthStatCard(title: "性别", value: gender, unit: "", icon: "person", color: .purple)
                        }
                        .padding(.horizontal)
                        
                        // BMI Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BMI 指数")
                                .font(.headline)
                            
                            HStack(alignment: .bottom, spacing: 8) {
                                Text(String(format: "%.1f", bmi))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(bmiColor)
                                
                                Text(bmiCategory)
                                    .font(.title3)
                                    .foregroundColor(bmiColor)
                                    .padding(.bottom, 4)
                            }
                            
                            ProgressView(value: min(max((bmi - 15) / 25, 0), 1))
                                .tint(bmiColor)
                            
                            HStack {
                                Text("偏瘦")
                                    .font(.caption)
                                Spacer()
                                Text("正常")
                                    .font(.caption)
                                Spacer()
                                Text("偏胖")
                                    .font(.caption)
                                Spacer()
                                Text("肥胖")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Achievements
                    VStack(alignment: .leading, spacing: 15) {
                        Text("成就徽章")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                AchievementBadge(
                                    title: "7天连续",
                                    icon: "flame.fill",
                                    color: .orange,
                                    isUnlocked: true
                                )
                                
                                AchievementBadge(
                                    title: "万步达人",
                                    icon: "figure.walk",
                                    color: .green,
                                    isUnlocked: true
                                )
                                
                                AchievementBadge(
                                    title: "早睡冠军",
                                    icon: "moon.stars.fill",
                                    color: .purple,
                                    isUnlocked: true
                                )
                                
                                AchievementBadge(
                                    title: "运动达人",
                                    icon: "figure.run",
                                    color: .blue,
                                    isUnlocked: false
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Settings List
                    VStack(alignment: .leading, spacing: 15) {
                        Text("设置")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            SettingsRow(icon: "bell.fill", title: "通知设置", color: .orange)
                            Divider().padding(.leading, 60)
                            
                            SettingsRow(icon: "lock.fill", title: "隐私与安全", color: .blue)
                            Divider().padding(.leading, 60)
                            
                            SettingsRow(icon: "chart.bar.fill", title: "数据统计", color: .green)
                            Divider().padding(.leading, 60)
                            
                            SettingsRow(icon: "heart.fill", title: "健康目标", color: .red)
                            Divider().padding(.leading, 60)
                            
                            SettingsRow(icon: "questionmark.circle.fill", title: "帮助与反馈", color: .purple)
                            Divider().padding(.leading, 60)
                            
                            SettingsRow(icon: "info.circle.fill", title: "关于 Aura", color: .gray)
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Logout Button
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("退出登录")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("个人中心")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(
                    userName: $userName,
                    height: $height,
                    weight: $weight,
                    age: $age,
                    gender: $gender
                )
            }
            .alert("退出登录", isPresented: $showingLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("退出", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .onAppear {
                // 加载用户配置
                if let profile = authViewModel.userProfile {
                    userName = profile.displayName ?? "健康达人"
                    userEmail = profile.email
                    height = Int(profile.height ?? 175)
                    weight = Int(profile.weight ?? 70)
                    age = profile.age ?? 28
                    gender = profile.gender == "male" ? "男" : profile.gender == "female" ? "女" : "男"
                }
            }
        }
    }
}

struct HealthStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color : Color.gray.opacity(0.3))
                    .frame(width: 70, height: 70)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isUnlocked ? .primary : .secondary)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 35, height: 35)
                    .background(color)
                    .cornerRadius(8)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var userName: String
    @Binding var height: Int
    @Binding var weight: Int
    @Binding var age: Int
    @Binding var gender: String
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("昵称", text: $userName)
                    
                    Picker("性别", selection: $gender) {
                        Text("男").tag("男")
                        Text("女").tag("女")
                    }
                    
                    Stepper("年龄: \(age) 岁", value: $age, in: 1...120)
                }
                
                Section(header: Text("身体数据")) {
                    Stepper("身高: \(height) cm", value: $height, in: 100...250)
                    
                    Stepper("体重: \(weight) kg", value: $weight, in: 30...200)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
