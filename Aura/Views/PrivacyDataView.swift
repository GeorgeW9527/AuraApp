//
//  PrivacyDataView.swift
//  Aura
//
//  Privacy & Data page
//

import SwiftUI

struct PrivacyDataView: View {
    @Environment(\.dismiss) private var dismiss

    private let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    private let textGray = Color(red: 0.45, green: 0.50, blue: 0.54)
    private let softGray = Color(red: 0.94, green: 0.95, blue: 0.96)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Data Collection Section
                    privacySection(
                        icon: "doc.text.magnifyingglass",
                        title: "Data We Collect",
                        content: """
                        Aura collects the following information to provide personalized health insights:

                        • Body Metrics: Height, weight, age, and gender for accurate calorie calculations
                        • Health Data: Resting heart rate, daily steps, and activity levels from HealthKit
                        • Nutrition Logs: Food intake records and meal photos you upload
                        • Device Information: Connected wearables and their sensor data

                        All data is encrypted and stored securely on our servers.
                        """
                    )

                    // Data Usage Section
                    privacySection(
                        icon: "brain.head.profile",
                        title: "How We Use Your Data",
                        content: """
                        Your data powers our AI to deliver:

                        • Personalized calorie and macronutrient recommendations
                        • Smart meal suggestions based on your goals
                        • Progress tracking and health trend analysis
                        • Tailored workout and recovery insights

                        We never sell your personal data to third parties.
                        """
                    )

                    // Data Storage Section
                    privacySection(
                        icon: "lock.shield",
                        title: "Data Security",
                        content: """
                        We implement industry-standard security measures:

                        • End-to-end encryption for sensitive health data
                        • Secure cloud storage with regular backups
                        • Access controls limiting data to authorized personnel only
                        • Regular security audits and compliance checks

                        Your data remains yours - you can request deletion at any time.
                        """
                    )

                    // Your Rights Section
                    privacySection(
                        icon: "person.badge.key",
                        title: "Your Rights",
                        content: """
                        You have complete control over your data:

                        • Export: Download all your data in standard formats
                        • Delete: Permanently remove your account and all associated data
                        • Modify: Update or correct any information at any time
                        • Opt-out: Disable data collection features you prefer not to use

                        Contact our support team for any data-related requests.
                        """
                    )

                    // Contact Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(deepGreen)

                        Text("If you have any questions about our privacy practices, please contact us at privacy@aura-health.com")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textGray)
                            .lineSpacing(3)
                    }
                    .padding(20)
                    .background(softGray)
                    .cornerRadius(16)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(red: 0.97, green: 0.98, blue: 0.96))
            .navigationTitle("Privacy & Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(deepGreen)
                    }
                }
            }
        }
    }

    private func privacySection(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(deepGreen)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(deepGreen)
            }

            Text(content)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(textGray)
                .lineSpacing(4)
        }
        .padding(20)
        .background(softGray)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        PrivacyDataView()
    }
}
