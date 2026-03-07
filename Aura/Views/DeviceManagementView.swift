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
        healthDataManager.batteryLevelPercent ?? 0
    }

    private var storageAvailable: Double {
        healthDataManager.storageAvailableGB
    }

    private var storageTotal: Double {
        healthDataManager.storageTotalGB
    }

    private var storageProgress: Double {
        guard storageTotal > 0 else { return 0 }
        return 1 - (storageAvailable / storageTotal)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                deviceInfoSection
                livePreviewSection
                hardwareStatusSection
                firmwareSection
                settingsSection
                unpairButton
            }
            .padding(.bottom, 32)
        }
        .background(Color(white: 0.97))
        .navigationTitle("Device Management")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body)
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

    // MARK: - Device Info（NutriCam Pro + CONNECTED + V1.4.2）

    private var deviceInfoSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NutriCam Pro")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.auraGreen)
                        .frame(width: 8, height: 8)
                    Text("CONNECTED")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.auraGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("V1.4.2")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.auraGrayDark)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.auraGreenLight)
                .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Live Preview

    private var livePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LIVE PREVIEW")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Text("1080p • 30fps")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.auraGreenLight)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.9))
                    .frame(height: 220)
                    .overlay(
                        Image(systemName: "video.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.auraGrayLight.opacity(0.5))
                    )
                Text("LIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.auraRed)
                    .cornerRadius(6)
                    .padding(12)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Hardware Status（Battery + Storage）

    private var hardwareStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HARDWARE STATUS")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                hardwareCard(
                    icon: "battery.75",
                    value: "\(batteryLevel)%",
                    label: "BATTERY",
                    progress: Double(batteryLevel) / 100
                )
                hardwareCard(
                    icon: "internaldrive.fill",
                    value: String(format: "%.1f GB", storageAvailable),
                    label: "STORAGE AVAILABLE",
                    progress: storageProgress
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func hardwareCard(icon: String, value: String, label: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color.auraGreen)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.auraGrayLight)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.auraGreen.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.auraGreen)
                        .frame(width: geo.size.width * CGFloat(min(progress, 1)))
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Firmware Update

    private var firmwareSection: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.auraGreen.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(Color.auraGreen)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("Firmware Update")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
                Text("Your device is up to date")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("CHECK") {
                // TODO: check firmware update
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.auraGreen)
            .cornerRadius(8)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(.caption)
                .foregroundColor(Color.auraGrayLight)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "cloud.fill")
                        .font(.title3)
                        .foregroundColor(Color.auraGrayLight)
                    Text("Auto-delete after sync")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                    Spacer()
                    Toggle("", isOn: $autoDeleteAfterSync)
                        .tint(Color.auraGreen)
                }
                .padding(14)

                Divider().padding(.leading, 56)

                HStack(spacing: 14) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.title3)
                        .foregroundColor(Color.auraGrayLight)
                    Text("Haptic Feedback")
                        .font(.subheadline)
                        .foregroundColor(Color.auraGrayDark)
                    Spacer()
                    Toggle("", isOn: $hapticFeedback)
                        .tint(Color.auraGreen)
                }
                .padding(14)

                Divider().padding(.leading, 56)

                Button {
                    // TODO: Reboot
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(Color.auraRed)
                        Text("Reboot NutriCam")
                            .font(.subheadline)
                            .foregroundColor(Color.auraRed)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.auraGrayLight)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Unpair Button

    private var unpairButton: some View {
        Button {
            showingUnpairAlert = true
        } label: {
            Text("UNPAIR DEVICE")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGrayDark)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.9))
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        DeviceManagementView()
            .environmentObject(HealthDataManager())
    }
}
