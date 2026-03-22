//
//  DeviceManagementView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

struct DeviceManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var healthDataManager: HealthDataManager
    @State private var autoDeleteAfterSync = true
    @State private var hapticFeedback = true
    @State private var showingUnpairAlert = false

    private var batteryLevel: Int {
        healthDataManager.batteryLevelPercent ?? 84
    }

    private var storageAvailable: Double {
        let value = healthDataManager.storageAvailableGB
        return value > 0 ? value : 2.4
    }

    private var storageTotal: Double {
        let value = healthDataManager.storageTotalGB
        return value > 0 ? value : 4.0
    }

    private var storageProgress: Double {
        guard storageTotal > 0 else { return 0.5 }
        return 1 - (storageAvailable / storageTotal)
    }

    // Colors matching device.png
    private let pageBackground = Color(red: 0.97, green: 0.98, blue: 0.96)
    private let deepGreen = Color(red: 0.11, green: 0.39, blue: 0.31)
    private let lime = Color(red: 0.84, green: 0.91, blue: 0.34)
    private let sectionLabel = Color(red: 0.58, green: 0.64, blue: 0.72)
    private let cardBorder = Color(red: 0.93, green: 0.95, blue: 0.97)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                deviceInfoSection
                livePreviewSection
                hardwareStatusSection
                firmwareSection
                settingsSection
                unpairButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(pageBackground)
        .navigationTitle("Device Management")
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
        .alert("Unpair Device", isPresented: $showingUnpairAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unpair", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to unpair NutriCam Pro?")
        }
        .task {
            await healthDataManager.refreshIfNeeded()
        }
    }

    // MARK: - Device Info

    private var deviceInfoSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("NutriCam Pro")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.22))

                HStack(spacing: 6) {
                    Circle()
                        .fill(deepGreen)
                        .frame(width: 8, height: 8)
                    Text("CONNECTED")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(deepGreen)
                }
            }

            Spacer()

            Text("V1.4.2")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.50, green: 0.55, blue: 0.62))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                .overlay(
                    Capsule().stroke(Color(red: 0.86, green: 0.89, blue: 0.93), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Live Preview

    private var livePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIVE PREVIEW")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(sectionLabel)

                Spacer()

                Text("1080p • 30fps")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(deepGreen)
            }

            ZStack(alignment: .topTrailing) {
                // Gradient background matching food image style
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.82, blue: 0.68),
                                Color(red: 0.88, green: 0.75, blue: 0.62)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay(
                        // Play button
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 2)
                            )
                    )

                // LIVE badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.35, green: 0.33, blue: 0.32))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(10)
            }
        }
    }

    // MARK: - Hardware Status

    private var hardwareStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HARDWARE STATUS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(sectionLabel)

            HStack(spacing: 12) {
                hardwareCard(
                    icon: "battery.100",
                    value: "\(batteryLevel)%",
                    unit: nil,
                    label: "Battery",
                    progress: Double(batteryLevel) / 100
                )
                hardwareCard(
                    icon: "externaldrive.fill",
                    value: String(format: "%.1f", storageAvailable),
                    unit: "GB",
                    label: "Storage Available",
                    progress: storageProgress
                )
            }
        }
    }

    private func hardwareCard(icon: String, value: String, unit: String?, label: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(deepGreen)
                    .frame(width: 20)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.22))
                    if let unit = unit {
                        Text(unit)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.68))
                    }
                }
            }

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.60))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.90, green: 0.93, blue: 0.96))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lime)
                        .frame(width: geo.size.width * CGFloat(min(progress, 1)))
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Firmware Update

    private var firmwareSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(deepGreen)

            VStack(alignment: .leading, spacing: 3) {
                Text("Firmware Update")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(deepGreen)
                Text("Your device is up to date")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.53))
            }

            Spacer()

            Text("CHECK")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(deepGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.80, green: 0.88, blue: 0.96), lineWidth: 1)
        )
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETTINGS")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(sectionLabel)

            VStack(spacing: 0) {
                // Auto-delete toggle
                HStack(spacing: 12) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.55, green: 0.62, blue: 0.72))

                    Text("Auto-delete after sync")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.22, green: 0.25, blue: 0.30))

                    Spacer()

                    Toggle("", isOn: $autoDeleteAfterSync)
                        .labelsHidden()
                        .tint(lime)
                        .scaleEffect(0.9)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider()
                    .padding(.leading, 44)

                // Haptic Feedback toggle
                HStack(spacing: 12) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.55, green: 0.62, blue: 0.72))

                    Text("Haptic Feedback")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.22, green: 0.25, blue: 0.30))

                    Spacer()

                    Toggle("", isOn: $hapticFeedback)
                        .labelsHidden()
                        .tint(lime)
                        .scaleEffect(0.9)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider()
                    .padding(.leading, 44)

                // Reboot button
                Button {
                    // TODO: reboot
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "power")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.red.opacity(0.8))

                        Text("Reboot NutriCam")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.red.opacity(0.8))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.70, green: 0.74, blue: 0.78))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Unpair Button

    private var unpairButton: some View {
        Button {
            showingUnpairAlert = true
        } label: {
            Text("UNPAIR DEVICE")
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundColor(Color(red: 0.58, green: 0.63, blue: 0.70))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DeviceManagementView()
            .environmentObject(HealthDataManager())
    }
}
