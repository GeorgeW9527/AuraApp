//
//  GoalSettingsView.swift
//  Aura
//
//  Goal Settings page matching goal.png design
//

import SwiftUI

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: HealthGoal = .weightLoss
    @EnvironmentObject var authViewModel: AuthViewModel

    init() {
        // Will be properly initialized in onAppear since EnvironmentObject isn't available in init
    }

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

        var icon: String {
            switch self {
            case .weightLoss: return "arrow.down.right"
            case .balancedDiet: return "fork.knife"
            case .buildMuscle: return "dumbbell.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.11, green: 0.20, blue: 0.22))

                    Text("This helps our AI calculate your daily caloric needs and macronutrient distribution.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.62))
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Goal Options
                VStack(spacing: 16) {
                    ForEach(HealthGoal.allCases, id: \.self) { goal in
                        GoalOptionRow(
                            goal: goal,
                            isSelected: selectedGoal == goal,
                            onTap: { selectedGoal = goal }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()

                // Bottom section
                VStack(spacing: 20) {
                    // Confirm Button
                    Button {
                        saveGoal()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Confirm")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.11, green: 0.20, blue: 0.22))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.84, green: 0.91, blue: 0.34))
                        )
                    }
                    .buttonStyle(.plain)

                    // Disclaimer
                    Text("Your data is safe. We use it only to personalize your health recommendations.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.70, green: 0.74, blue: 0.76))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(red: 0.97, green: 0.98, blue: 0.96))
            .navigationTitle("Primary Health Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.11, green: 0.20, blue: 0.22))
                    }
                }
            }
            .onAppear {
                loadSavedGoal()
            }
        }
    }

    private func loadSavedGoal() {
        if let savedGoal = authViewModel.userProfile?.healthGoal,
           let goal = HealthGoal(rawValue: savedGoal) {
            selectedGoal = goal
        }
    }

    private func saveGoal() {
        Task {
            guard var profile = authViewModel.userProfile,
                  let currentUser = authViewModel.currentUser else {
                dismiss()
                return
            }
            profile.healthGoal = selectedGoal.rawValue
            profile.updatedAt = Date()
            await authViewModel.updateUserProfile(profile)
            dismiss()
        }
    }
}

// MARK: - Goal Option Row
struct GoalOptionRow: View {
    let goal: GoalSettingsView.HealthGoal
    let isSelected: Bool
    let onTap: () -> Void

    private var backgroundColor: Color {
        isSelected ? Color(red: 0.95, green: 0.99, blue: 0.96) : Color.white
    }

    private var borderColor: Color {
        isSelected ? Color(red: 0.11, green: 0.39, blue: 0.31) : Color(red: 0.88, green: 0.90, blue: 0.92)
    }

    private var iconBackgroundColor: Color {
        isSelected ? Color(red: 0.11, green: 0.39, blue: 0.31) : Color(red: 0.94, green: 0.96, blue: 0.97)
    }

    private var iconColor: Color {
        isSelected ? .white : Color(red: 0.55, green: 0.60, blue: 0.62)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconBackgroundColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: goal.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(iconColor)
                    )

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.11, green: 0.20, blue: 0.22))

                    Text(goal.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.62))
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color(red: 0.75, green: 0.78, blue: 0.80), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.11, green: 0.39, blue: 0.31))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalSettingsView()
        .environmentObject(AuthViewModel())
}
