//
//  HealthProfileQuestionnaireView.swift
//  Aura
//
//  开机问卷 Step 2 - 参考 问卷.png
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
    @State private var useMetric = true
    @State private var heightText = "175"
    @State private var weightText = "72.5"
    @State private var heartRateText = "65"
    @State private var selectedGoal: HealthGoal = .weightLoss
    @State private var isSubmitting = false

    private let currentStep = 2
    private let totalSteps = 4
    private var progress: Double { Double(currentStep) / Double(totalSteps) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    progressHeader
                    physicalDetailsSection
                    healthGoalSection
                    continueButton
                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Health Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.auraGreen)
                Spacer()
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.9))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.auraGreen)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.top, 8)
    }

    private var physicalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your physical details")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
            Text("This helps our AI calculate your daily caloric needs and macronutrient distribution.")
                .font(.subheadline)
                .foregroundColor(Color.auraGrayLight)

            HStack(spacing: 0) {
                Button { useMetric = true } label: {
                    Text("Metric")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(useMetric ? Color.auraGrayDark : Color.auraGrayLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(useMetric ? Color.white : Color(white: 0.94))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                Button { useMetric = false } label: {
                    Text("Imperial")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(!useMetric ? Color.auraGrayDark : Color.auraGrayLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!useMetric ? Color.white : Color(white: 0.94))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(Color(white: 0.94))
            .cornerRadius(10)

            VStack(spacing: 12) {
                inputField(
                    label: useMetric ? "Height (cm)" : "Height (ft in)",
                    text: $heightText,
                    trailing: AnyView(Image(systemName: "arrow.up.arrow.down"))
                )
                inputField(
                    label: useMetric ? "Current Weight (kg)" : "Current Weight (lb)",
                    text: $weightText,
                    trailing: nil
                )
                inputField(
                    label: "Resting Heart Rate (BPM)",
                    text: $heartRateText,
                    trailing: AnyView(Image(systemName: "heart.fill").foregroundColor(Color.auraGrayLight))
                )
            }
        }
    }

    private func inputField(label: String, text: Binding<String>, trailing: AnyView?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.auraGrayDark)
            HStack {
                TextField("", text: text)
                    .keyboardType(.decimalPad)
                    .font(.body)
                if let t = trailing {
                    t.font(.body)
                }
            }
            .padding(12)
            .background(Color(white: 0.95))
            .cornerRadius(10)
        }
    }

    private var healthGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary health goal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
            ForEach(HealthGoal.allCases, id: \.self) { goal in
                goalCard(goal)
            }
        }
    }

    private func goalCard(_ goal: HealthGoal) -> some View {
        let isSelected = selectedGoal == goal
        return Button {
            selectedGoal = goal
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.auraGreen.opacity(0.2) : Color(white: 0.92))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: goal.iconName)
                            .font(.title3)
                            .foregroundColor(isSelected ? Color.auraGreen : Color.auraGrayLight)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.auraGrayDark)
                    Text(goal.subtitle)
                        .font(.caption)
                        .foregroundColor(Color.auraGrayLight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Group {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.auraGreen)
                    } else {
                        Circle()
                            .stroke(Color.auraGrayLight, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.auraGreen : Color(white: 0.9), lineWidth: isSelected ? 2 : 1)
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
                    .fontWeight(.bold)
                Image(systemName: "arrow.right")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.auraGreen)
            .cornerRadius(14)
        }
        .disabled(isSubmitting)
        .padding(.top, 8)
    }

    private var privacyNote: some View {
        Text("Your data is safe. We use it only to personalize your health recommendations.")
            .font(.caption)
            .foregroundColor(Color.auraGrayLight)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
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
