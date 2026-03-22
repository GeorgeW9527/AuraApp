//
//  BodyProfileView.swift
//  Aura
//
//  Body Profile editing page matching body.png design
//

import SwiftUI
import FirebaseAuth

struct BodyProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var height: Double = 175.0
    @State private var weight: Double = 72.5
    @State private var restingHeartRate: Int = 65
    @State private var useMetric: Bool = true
    @State private var isSaving: Bool = false

    // Colors
    private let limeGreen = Color(red: 0.84, green: 0.91, blue: 0.34)
    private let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    private let softGray = Color(red: 0.94, green: 0.95, blue: 0.96)
    private let textGray = Color(red: 0.45, green: 0.50, blue: 0.54)
    private let darkText = Color(red: 0.11, green: 0.20, blue: 0.22)

    private var heightLabel: String {
        useMetric ? "Height (cm)" : "Height (ft)"
    }

    private var weightLabel: String {
        useMetric ? "Current Weight (kg)" : "Current Weight (lb)"
    }

    private var heightDisplay: String {
        if useMetric {
            return String(format: "%.0f", height)
        } else {
            // Convert cm to ft/in
            let totalInches = height / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        }
    }

    private var weightDisplay: String {
        if useMetric {
            return String(format: "%.1f", weight)
        } else {
            // Convert kg to lb
            let lbs = weight * 2.20462
            return String(format: "%.1f", lbs)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Body Profile")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(darkText)

                        Text("This helps our AI calculate your daily caloric needs and macronutrient distribution.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(textGray)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Metric/Imperial Toggle
                    HStack(spacing: 4) {
                        Button {
                            useMetric = true
                        } label: {
                            Text("Metric")
                                .font(.system(size: 15, weight: useMetric ? .bold : .medium))
                                .foregroundColor(useMetric ? darkText : textGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(useMetric ? Color.white : softGray)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button {
                            useMetric = false
                        } label: {
                            Text("Imperial")
                                .font(.system(size: 15, weight: !useMetric ? .bold : .medium))
                                .foregroundColor(!useMetric ? darkText : textGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(!useMetric ? Color.white : softGray)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(softGray)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Height Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(heightLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textGray)

                        HStack {
                            TextField("", value: $height, format: .number)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(darkText)
                                .keyboardType(.decimalPad)

                            Spacer()

                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.70, green: 0.75, blue: 0.78))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(softGray)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(weightLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textGray)

                        TextField("", value: $weight, format: .number)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(darkText)
                            .keyboardType(.decimalPad)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(softGray)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Resting Heart Rate Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resting Heart Rate (BPM)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textGray)

                        HStack {
                            TextField("", value: $restingHeartRate, format: .number)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(darkText)
                                .keyboardType(.numberPad)

                            Spacer()

                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.70, green: 0.75, blue: 0.78))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(softGray)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    // Bottom section
                    VStack(spacing: 16) {
                        // Confirm Button
                        Button {
                            saveProfile()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Confirm")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(darkText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(limeGreen)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)

                        // Disclaimer
                        Text("Your data is safe. We use it only to personalize your health recommendations.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.70, green: 0.74, blue: 0.76))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(red: 0.97, green: 0.98, blue: 0.96))
            .navigationTitle("Body Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(darkText)
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    private func loadCurrentValues() {
        guard let profile = authViewModel.userProfile else { return }

        useMetric = profile.useMetric ?? true
        height = profile.height ?? 175.0
        weight = profile.weight ?? 70.0
        restingHeartRate = profile.restingHeartRate ?? 65
    }

    private func saveProfile() {
        Task {
            isSaving = true

            guard var profile = authViewModel.userProfile,
                  let currentUser = authViewModel.currentUser else {
                isSaving = false
                dismiss()
                return
            }

            // Update profile with new values
            profile.height = height
            profile.weight = weight
            profile.restingHeartRate = restingHeartRate
            profile.useMetric = useMetric
            profile.updatedAt = Date()

            await authViewModel.updateUserProfile(profile)
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        BodyProfileView()
            .environmentObject(AuthViewModel())
    }
}
