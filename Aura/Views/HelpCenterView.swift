//
//  HelpCenterView.swift
//  Aura
//
//  Help Center page
//

import SwiftUI

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss

    private let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    private let textGray = Color(red: 0.45, green: 0.50, blue: 0.54)
    private let softGray = Color(red: 0.94, green: 0.95, blue: 0.96)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Getting Started
                    helpSection(
                        icon: "star.fill",
                        title: "Getting Started",
                        items: [
                            "How to set up your profile",
                            "Connecting your wearable device",
                            "Logging your first meal",
                            "Understanding your health score"
                        ]
                    )

                    // Features Guide
                    helpSection(
                        icon: "sparkles",
                        title: "Features Guide",
                        items: [
                            "Using AI meal analysis",
                            "Setting health goals",
                            "Viewing Smart Reports",
                            "Tracking daily progress"
                        ]
                    )

                    // Troubleshooting
                    helpSection(
                        icon: "wrench.fill",
                        title: "Troubleshooting",
                        items: [
                            "HealthKit connection issues",
                            "Sync problems with devices",
                            "App performance tips",
                            "Data backup and restore"
                        ]
                    )

                    // Contact Support
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Still need help?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(deepGreen)

                        Text("Our support team is available Monday through Friday, 9AM - 6PM EST.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textGray)
                            .lineSpacing(3)

                        Button {
                            // Open email client
                            if let url = URL(string: "mailto:support@aura-health.com") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(deepGreen)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
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
            .navigationTitle("Help Center")
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

    private func helpSection(icon: String, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(deepGreen)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(deepGreen)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.self) { item in
                    Button {
                        // Handle FAQ item tap
                    } label: {
                        HStack {
                            Text(item)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(textGray)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(textGray.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(softGray)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}
