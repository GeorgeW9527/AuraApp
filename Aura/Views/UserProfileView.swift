//
//  UserProfileView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var userName = "Alex Rivera"
    @State private var userEmail = "user@aura.com"
    @State private var height = 175
    @State private var weight = 70
    @State private var age = 28
    @State private var gender = "男"
    @State private var notificationsEnabled = true
    @State private var useMetric = true
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    @State private var isSavingProfile = false

    private var userShortId: String {
        let uid = authViewModel.currentUser?.uid ?? "0000"
        let suffix = String(uid.suffix(4))
        return "AI-\(suffix)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                aiHealthScoreCard
                healthDataSection
                systemSection
                supportSection
                footer
            }
            .padding(.bottom, 32)
        }
        .background(Color(white: 0.97))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(Color.auraGrayDark)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(
                userName: $userName,
                height: $height,
                weight: $weight,
                age: $age,
                gender: $gender,
                isSaving: $isSavingProfile,
                onSave: saveProfile
            )
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .task {
            await authViewModel.loadUserProfile()
            applyProfileToLocalState()
        }
        .onChange(of: authViewModel.userProfile?.updatedAt) {
            applyProfileToLocalState()
        }
    }

    // MARK: - Profile Header（头像 + 姓名 + ID）

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.auraGreen, lineWidth: 2)
                    )
                Text(String(userName.prefix(1)))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                Circle()
                    .fill(Color.auraGreen)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: -4, y: -4)
            }
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
            Text("ID: \(userShortId)")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
        }
        .padding(.top, 20)
    }

    // MARK: - AI Health Score Card

    private var aiHealthScoreCard: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.auraGreen.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundColor(Color.auraGreen)
                )
            VStack(alignment: .leading, spacing: 6) {
                Text("AI HEALTH SCORE")
                    .font(.caption2)
                    .foregroundColor(Color.auraGreen)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("84 / 100")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.auraGrayDark)
                    Text("OPTIMAL")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.auraGreen)
                        .cornerRadius(12)
                }
                Text("Updated 2h ago")
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding(16)
        .background(Color.auraGreenLight)
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }

    // MARK: - HEALTH DATA Section

    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEALTH DATA")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                SettingsNavRow(
                    icon: "person",
                    iconColor: Color.auraGreen,
                    title: "Body Profile",
                    subtitle: "Height, Weight, Biometrics"
                ) { showingEditProfile = true }

                Divider().padding(.leading, 56)

                SettingsNavRow(
                    icon: "target",
                    iconColor: Color.auraGreen,
                    title: "Goal Settings",
                    subtitle: "Daily calorie & nutrition targets",
                    showAIBadge: true
                ) { /* TODO */ }

                Divider().padding(.leading, 56)

                SettingsNavRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color.auraGreen,
                    title: "Smart Report",
                    subtitle: "Comprehensive health & nutrition insights"
                ) { /* TODO */ }
            }
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - SYSTEM Section

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SYSTEM")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    SettingsIconView(icon: "bell.fill", color: Color.auraGreen)
                    Text("Notifications")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                    Spacer()
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(Color.auraGreen)
                }
                .padding(14)

                Divider().padding(.leading, 56)

                SettingsNavRow(
                    icon: "shield.fill",
                    iconColor: Color.auraGreen,
                    title: "Privacy & Data",
                    subtitle: nil
                ) { /* TODO */ }

                Divider().padding(.leading, 56)

                HStack(spacing: 14) {
                    SettingsIconView(icon: "ruler", color: Color.auraGreen)
                    Text("Measurement Units")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                    Spacer()
                    HStack(spacing: 0) {
                        Button { useMetric = true } label: {
                            Text("Metric")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(useMetric ? Color.auraGrayDark : Color.auraGrayLight)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(useMetric ? Color(white: 0.92) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        Button { useMetric = false } label: {
                            Text("Imperial")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(!useMetric ? Color.auraGrayDark : Color.auraGrayLight)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(!useMetric ? Color(white: 0.92) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(2)
                    .background(Color(white: 0.95))
                    .cornerRadius(10)
                }
                .padding(14)
            }
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - SUPPORT Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUPPORT")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                SettingsNavRow(
                    icon: "questionmark.circle",
                    iconColor: Color.auraGrayLight,
                    title: "Help Center",
                    subtitle: nil,
                    showExternalLink: true
                ) { /* TODO */ }

                Divider().padding(.leading, 56)

                Button {
                    showingLogoutAlert = true
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconView(icon: "rectangle.portrait.and.arrow.right", color: Color.auraRed)
                        Text("Log Out")
                            .font(.subheadline)
                            .foregroundColor(Color.auraRed)
                        Spacer()
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundColor(Color.auraGreen)
                Text("Au")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
                Text("ra")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGreen)
            }
            .padding(.top, 24)
            Text("VERSION 2.4.1 (BUILD 882)")
                .font(.caption2)
                .foregroundColor(Color.auraGrayLight)
        }
    }

    // MARK: - Helpers

    private func applyProfileToLocalState() {
        guard let profile = authViewModel.userProfile else { return }
        userName = profile.displayName ?? "Alex Rivera"
        userEmail = profile.email
        height = Int(profile.height ?? 175)
        weight = Int(profile.weight ?? 70)
        age = profile.age ?? 28
        gender = profile.gender == "female" ? "女" : "男"
    }

    private func saveProfile() async {
        guard let currentUser = authViewModel.currentUser else { return }
        isSavingProfile = true
        let profile = UserProfile(
            id: authViewModel.userProfile?.id,
            userId: currentUser.uid,
            displayName: userName.isEmpty ? "Alex Rivera" : userName,
            email: authViewModel.userProfile?.email ?? currentUser.email ?? userEmail,
            avatarURL: authViewModel.userProfile?.avatarURL,
            age: age,
            gender: gender == "女" ? "female" : "male",
            height: Double(height),
            weight: Double(weight),
            targetWeight: authViewModel.userProfile?.targetWeight,
            dailyCalorieGoal: authViewModel.userProfile?.dailyCalorieGoal,
            createdAt: authViewModel.userProfile?.createdAt ?? Date(),
            updatedAt: Date()
        )
        await authViewModel.updateUserProfile(profile)
        isSavingProfile = false
    }
}

// MARK: - Settings Row Components

struct SettingsIconView: View {
    let icon: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color.opacity(0.2))
            .frame(width: 36, height: 36)
            .overlay(Image(systemName: icon).font(.subheadline).foregroundColor(color))
    }
}

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var showAIBadge = false
    var showExternalLink = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    SettingsIconView(icon: icon, color: iconColor)
                    if showAIBadge {
                        Text("AI")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(2)
                            .background(Color.auraGreen)
                            .cornerRadius(4)
                            .offset(x: 4, y: -4)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.auraGrayDark)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundColor(Color.auraGrayLight)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if showExternalLink {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                }
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile（保留原有）

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userName: String
    @Binding var height: Int
    @Binding var weight: Int
    @Binding var age: Int
    @Binding var gender: String
    @Binding var isSaving: Bool
    let onSave: () async -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Name", text: $userName)
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("男")
                        Text("Female").tag("女")
                    }
                    Stepper("Age: \(age)", value: $age, in: 1...120)
                }
                Section(header: Text("Body Data")) {
                    Stepper("Height: \(height) cm", value: $height, in: 100...250)
                    Stepper("Weight: \(weight) kg", value: $weight, in: 30...200)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await onSave()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.auraGreen)
                    .disabled(isSaving)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView()
            .environmentObject(AuthViewModel())
    }
}
