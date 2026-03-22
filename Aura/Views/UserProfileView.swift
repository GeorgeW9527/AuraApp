//
//  UserProfileView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI
import FirebaseAuth
import UIKit

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var height = 175
    @State private var weight = 70
    @State private var age = 28
    @State private var gender = "男"
    @State private var restingHeartRate = 65
    @State private var healthGoalRaw = "weight_loss"
    @State private var notificationsEnabled = true
    @State private var useMetric = true
    @State private var showingLogoutAlert = false
    @State private var isSavingProfile = false
    @State private var showingAvatarSourceSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedAvatarImage: UIImage?

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
        .background(Color(red: 0.97, green: 0.98, blue: 0.96))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.auraGrayDark)
                }
            }
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

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Button {
                showingAvatarSourceSheet = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    avatarView
                    Circle()
                        .fill(Color(red: 0.11, green: 0.39, blue: 0.31))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .confirmationDialog("Change Avatar", isPresented: $showingAvatarSourceSheet) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        showingCamera = true
                    }
                }
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select avatar source")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedAvatarImage, onImageSelected: {
                    showingImagePicker = false
                    handleAvatarSelected()
                })
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $selectedAvatarImage, onImageCaptured: {
                    showingCamera = false
                    handleAvatarSelected()
                })
            }
            Text(userName.isEmpty ? "User" : userName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.auraGrayDark)
            Text("ID: \(userShortId)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.auraGrayLight)
        }
        .padding(.top, 16)
    }

    private func handleAvatarSelected() {
        guard let image = selectedAvatarImage else { return }
        LocalStorageManager.shared.saveUserAvatar(image)
        Task {
            await authViewModel.uploadAvatar(image)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let image = selectedAvatarImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(red: 0.11, green: 0.39, blue: 0.31), lineWidth: 3))
        } else if let localImage = LocalStorageManager.shared.loadUserAvatar() {
            Image(uiImage: localImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(red: 0.11, green: 0.39, blue: 0.31), lineWidth: 3))
        } else if let urlString = authViewModel.userProfile?.avatarURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    avatarPlaceholder
                case .empty:
                    ProgressView()
                @unknown default:
                    avatarPlaceholder
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(red: 0.11, green: 0.39, blue: 0.31), lineWidth: 3))
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.84, green: 0.91, blue: 0.34).opacity(0.6), Color(red: 0.84, green: 0.91, blue: 0.34)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 90, height: 90)
            .overlay(Circle().stroke(Color(red: 0.11, green: 0.39, blue: 0.31), lineWidth: 3))
            .overlay(
                Text(String((userName.isEmpty ? "U" : userName).prefix(1)))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31))
            )
    }

    // MARK: - AI Health Score Card

    private var aiHealthScoreCard: some View {
        HStack(alignment: .center, spacing: 16) {
            // Chart icon in dark green circle
            Circle()
                .fill(Color(red: 0.11, green: 0.39, blue: 0.31))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("AI HEALTH SCORE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("84")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31))
                    Text("/100")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31).opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // OPTIMAL badge
            VStack(alignment: .trailing, spacing: 4) {
                Text("OPTIMAL")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.11, green: 0.39, blue: 0.31))
                    )

                Text("Updated 2h ago")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31).opacity(0.7))
            }
        }
        .padding(16)
        .background(Color(red: 0.84, green: 0.91, blue: 0.34))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    // MARK: - HEALTH DATA Section

    private var bodyProfileSubtitle: String {
        let h = useMetric ? "\(height) cm" : "\(Int(Double(height) * 0.0328084)) ft"
        let w = useMetric ? "\(weight) kg" : "\(Int(Double(weight) * 2.205)) lb"
        return "Height, Weight, Biometrics"
    }

    private var healthDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEALTH DATA")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                NavigationLink(destination: BodyProfileView()) {
                    SettingsNavRowContent(
                        icon: "person.fill",
                        iconColor: Color(red: 0.11, green: 0.39, blue: 0.31),
                        title: "Body Profile",
                        subtitle: "Height, Weight, Biometrics"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                NavigationLink(destination: GoalSettingsView()) {
                    SettingsNavRowContent(
                        icon: "target",
                        iconColor: Color(red: 0.11, green: 0.39, blue: 0.31),
                        title: "Goal Settings",
                        subtitle: "Daily calorie & nutrition targets",
                        showAIBadge: true
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                NavigationLink(destination: SmartReportView()) {
                    SettingsNavRowContent(
                        icon: "chart.bar.fill",
                        iconColor: Color(red: 0.11, green: 0.39, blue: 0.31),
                        title: "Smart Report",
                        subtitle: "Comprehensive health & nutrition insights"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                NavigationLink(destination: HealthProfileQuestionnaireView()) {
                    SettingsNavRowContent(
                        icon: "clipboard.fill",
                        iconColor: Color(red: 0.11, green: 0.39, blue: 0.31),
                        title: "Health Questionnaire",
                        subtitle: "Review and update your health profile"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - SYSTEM Section

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SYSTEM")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    SettingsIconView(icon: "bell.fill", color: Color(red: 0.11, green: 0.39, blue: 0.31))
                    Text("Notifications")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.auraGrayDark)
                    Spacer()
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(Color(red: 0.84, green: 0.91, blue: 0.34))
                }
                .padding(16)

                Divider().padding(.leading, 56)

                NavigationLink(destination: PrivacyDataView()) {
                    SettingsNavRowContent(
                        icon: "shield.fill",
                        iconColor: Color(red: 0.11, green: 0.39, blue: 0.31),
                        title: "Privacy & Data",
                        subtitle: nil
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - SUPPORT Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUPPORT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                NavigationLink(destination: HelpCenterView()) {
                    SettingsNavRowContent(
                        icon: "questionmark.circle.fill",
                        iconColor: Color(red: 0.11, green: 0.39, blue: 0.31),
                        title: "Help Center",
                        subtitle: nil,
                        showExternalLink: true
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                Button {
                    showingLogoutAlert = true
                } label: {
                    HStack(spacing: 14) {
                        SettingsIconView(icon: "rectangle.portrait.and.arrow.right", color: Color.auraRed)
                        Text("Log Out")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.auraRed)
                        Spacer()
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 2) {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31))
                Text("Bio")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31))
                Text("AI")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.11, green: 0.39, blue: 0.31))
            }
            .padding(.top, 32)
            Text("VERSION 2.4.1 (BUILD 882)")
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .foregroundColor(Color.auraGrayLight)
        }
    }

    // MARK: - Helpers

    private func applyProfileToLocalState() {
        guard let profile = authViewModel.userProfile else { return }
        userName = profile.displayName ?? ""
        userEmail = profile.email.isEmpty ? (authViewModel.currentUser?.email ?? "") : profile.email
        height = Int(profile.height ?? 175)
        weight = Int(profile.weight ?? 70)
        age = profile.age ?? 28
        gender = profile.gender == "female" ? "女" : "男"
        restingHeartRate = profile.restingHeartRate ?? 65
        healthGoalRaw = profile.healthGoal ?? "balanced_diet"
        useMetric = profile.useMetric ?? true
    }

    private func saveProfile() async {
        guard let currentUser = authViewModel.currentUser else { return }
        isSavingProfile = true
        let profile = UserProfile(
            id: authViewModel.userProfile?.id,
            userId: currentUser.uid,
            displayName: userName.isEmpty ? nil : userName,
            email: authViewModel.userProfile?.email ?? currentUser.email ?? userEmail,
            avatarURL: authViewModel.userProfile?.avatarURL,
            age: age,
            gender: gender == "女" ? "female" : "male",
            height: Double(height),
            weight: Double(weight),
            targetWeight: authViewModel.userProfile?.targetWeight,
            dailyCalorieGoal: authViewModel.userProfile?.dailyCalorieGoal,
            restingHeartRate: restingHeartRate,
            healthGoal: healthGoalRaw,
            useMetric: useMetric,
            hasCompletedQuestionnaire: authViewModel.userProfile?.hasCompletedQuestionnaire,
            createdAt: authViewModel.userProfile?.createdAt ?? Date(),
            updatedAt: Date()
        )
        await authViewModel.updateUserProfile(profile)
        isSavingProfile = false
    }

    private func saveProfileIfNeeded() async {
        guard authViewModel.currentUser != nil,
              var profile = authViewModel.userProfile else { return }
        profile.useMetric = useMetric
        profile.updatedAt = Date()
        await authViewModel.updateUserProfile(profile)
    }
}

// MARK: - Settings Row Components

struct SettingsIconView: View {
    let icon: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(red: 0.92, green: 0.96, blue: 0.92))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            )
    }
}

struct SettingsNavRowContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var showAIBadge = false
    var showExternalLink = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                SettingsIconView(icon: icon, color: iconColor)
                if showAIBadge {
                    Text("AI")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.11, green: 0.39, blue: 0.31))
                        .cornerRadius(5)
                        .offset(x: 6, y: -6)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.auraGrayDark)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.auraGrayLight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showExternalLink {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.auraGrayLight)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.auraGrayLight)
            }
        }
        .padding(16)
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
            SettingsNavRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
                showAIBadge: showAIBadge,
                showExternalLink: showExternalLink
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Header Avatar (reusable across tabs)

struct ProfileHeaderAvatarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var size: CGFloat = 44

    private var displayName: String {
        authViewModel.userProfile?.displayName ?? "User"
    }

    var body: some View {
        Group {
            if let localImage = LocalStorageManager.shared.loadUserAvatar() {
                Image(uiImage: localImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let urlString = authViewModel.userProfile?.avatarURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.auraGreen.opacity(0.3))
            .overlay(
                Text(String(displayName.prefix(1)).isEmpty ? "U" : String(displayName.prefix(1)))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(Color.auraGreen)
            )
    }
}

#Preview {
    NavigationStack {
        UserProfileView()
            .environmentObject(AuthViewModel())
    }
}
