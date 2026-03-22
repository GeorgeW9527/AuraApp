//
//  HealthProfileQuestionnaireView.swift
//  Aura
//
//  开机问卷 Step 2 - 参考 question.png
//

import SwiftUI
import FirebaseAuth

enum HealthGoal: String, CaseIterable {
    case weightLoss = "weight_loss"
    case balancedDiet = "balanced_diet"
    case buildMuscle = "build_muscle"
    var title: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .balancedDiet: return "Balanced Diet"
        case .buildMuscle: return "Build Muscle"
        }
    }
    var subtitle: String {
        switch self {
        case .weightLoss: return "Sustainable fat burning focus"
        case .balancedDiet: return "Maintenance and vitality"
        case .buildMuscle: return "High protein & strength support"
        }
    }
    var iconName: String {
        switch self {
        case .weightLoss: return "arrow.down.right"
        case .balancedDiet: return "fork.knife"
        case .buildMuscle: return "dumbbell.fill"
        }
    }
}

struct HealthProfileQuestionnaireView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var useMetric = true
    @State private var heightText = "175"
    @State private var weightText = "72.5"
    @State private var heartRateText = "65"
    @State private var selectedGoal: HealthGoal = .weightLoss
    @State private var isSubmitting = false

    // Colors matching question.png
    private let pageBackground = Color(red: 0.97, green: 0.98, blue: 0.96)
    private let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    private let lime = Color(red: 0.84, green: 0.91, blue: 0.34)
    private let labelColor = Color(red: 0.58, green: 0.64, blue: 0.72)
    private let fieldBackground = Color(red: 0.96, green: 0.97, blue: 0.98)
    private let cardBorder = Color(red: 0.88, green: 0.91, blue: 0.95)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    physicalDetailsSection
                    healthGoalSection
                    continueButton
                    privacyNote
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(pageBackground)
            .navigationTitle("HEALTH PROFILE")
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
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your health details")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.20))
            Text("This helps our AI calculate your daily caloric needs and macronutrient distribution.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(red: 0.50, green: 0.55, blue: 0.60))
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var physicalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Metric/Imperial Toggle
            HStack(spacing: 4) {
                Button { useMetric = true } label: {
                    Text("Metric")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(useMetric ? Color(red: 0.15, green: 0.18, blue: 0.22) : labelColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(useMetric ? Color.white : fieldBackground)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button { useMetric = false } label: {
                    Text("Imperial")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(!useMetric ? Color(red: 0.15, green: 0.18, blue: 0.22) : labelColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(!useMetric ? Color.white : fieldBackground)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(fieldBackground)
            .cornerRadius(12)

            // Input Fields
            VStack(spacing: 16) {
                // Height
                VStack(alignment: .leading, spacing: 6) {
                    Text(useMetric ? "Height (cm)" : "Height (ft)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(labelColor)

                    HStack {
                        TextField("", text: $heightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.38, blue: 0.42))
                        Spacer()
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.75, green: 0.78, blue: 0.82))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(fieldBackground)
                    .cornerRadius(16)
                }

                // Weight
                VStack(alignment: .leading, spacing: 6) {
                    Text(useMetric ? "Current Weight (kg)" : "Current Weight (lb)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(labelColor)

                    TextField("", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.35, green: 0.38, blue: 0.42))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(fieldBackground)
                        .cornerRadius(16)
                }

                // Heart Rate
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resting Heart Rate (BPM)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(labelColor)

                    HStack {
                        TextField("", text: $heartRateText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.38, blue: 0.42))
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.80, green: 0.82, blue: 0.85))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(fieldBackground)
                    .cornerRadius(16)
                }
            }
        }
    }

    private var healthGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary health goal")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.20))

            ForEach(HealthGoal.allCases, id: \.self) { goal in
                goalCard(goal)
            }
        }
    }

    private func goalCard(_ goal: HealthGoal) -> some View {
        let isSelected = selectedGoal == goal
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedGoal = goal
            }
        } label: {
            HStack(spacing: 14) {
                // Icon in rounded square
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? deepGreen : fieldBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: goal.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color(red: 0.55, green: 0.60, blue: 0.65))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.22))
                    Text(goal.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.50, green: 0.55, blue: 0.60))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(deepGreen)
                } else {
                    Circle()
                        .stroke(Color(red: 0.82, green: 0.85, blue: 0.88), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? deepGreen : cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button {
            submitQuestionnaire()
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(deepGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(lime)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .padding(.top, 8)
    }

    private var privacyNote: some View {
        Text("Your data is safe. We use it only to personalize your health recommendations.")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(red: 0.65, green: 0.68, blue: 0.72))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
    }

    private func submitQuestionnaire() {
        guard let userId = authViewModel.currentUser?.uid,
              let email = authViewModel.currentUser?.email else { return }
        let heightVal = Double(heightText) ?? 175
        let weightVal = Double(weightText) ?? 72.5
        let heartVal = Int(heartRateText) ?? 65
        isSubmitting = true
        let profile = UserProfile(
            userId: userId,
            displayName: authViewModel.userProfile?.displayName,
            email: email,
            avatarURL: authViewModel.userProfile?.avatarURL,
            age: authViewModel.userProfile?.age,
            gender: authViewModel.userProfile?.gender,
            height: heightVal,
            weight: weightVal,
            targetWeight: authViewModel.userProfile?.targetWeight,
            dailyCalorieGoal: authViewModel.userProfile?.dailyCalorieGoal,
            restingHeartRate: heartVal,
            healthGoal: selectedGoal.rawValue,
            useMetric: useMetric,
            hasCompletedQuestionnaire: true,
            createdAt: authViewModel.userProfile?.createdAt ?? Date(),
            updatedAt: Date()
        )
        Task {
            authViewModel.userProfile = profile
            LocalStorageManager.shared.saveUserProfile(profile)
            do {
                try await FirebaseManager.shared.saveData(
                    collection: "userProfiles",
                    documentId: userId,
                    data: profile
                )
                print("✅ 问卷数据已保存到本地和云端")
            } catch {
                print("⚠️ 问卷云端保存失败（本地已保存）: \(error)")
            }
            await MainActor.run { isSubmitting = false }
        }
    }
}

#Preview {
    HealthProfileQuestionnaireView()
        .environmentObject(AuthViewModel())
}
