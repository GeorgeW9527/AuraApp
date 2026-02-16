//
//  DeviceManagementView.swift
//  Aura
//
//  Created by jiazhen yan on 2026/2/10.
//

import SwiftUI

struct DeviceManagementView: View {
    @State private var connectedDevices: [HealthDevice] = [
        HealthDevice(name: "Apple Watch Series 9", type: .smartWatch, isConnected: true, batteryLevel: 85, lastSync: Date()),
        HealthDevice(name: "智能体重秤", type: .scale, isConnected: true, batteryLevel: 70, lastSync: Date().addingTimeInterval(-3600)),
        HealthDevice(name: "智能手环", type: .fitnessBand, isConnected: false, batteryLevel: 45, lastSync: Date().addingTimeInterval(-86400))
    ]
    
    @State private var showingAddDevice = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    HStack(spacing: 15) {
                        DeviceStatCard(
                            title: "已连接",
                            value: "\(connectedDevices.filter { $0.isConnected }.count)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        DeviceStatCard(
                            title: "设备总数",
                            value: "\(connectedDevices.count)",
                            icon: "antenna.radiowaves.left.and.right",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Connected Devices
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("我的设备")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddDevice = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(connectedDevices) { device in
                            DeviceCard(device: device) {
                                toggleConnection(device: device)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Sync Info
                    VStack(alignment: .leading, spacing: 15) {
                        Text("同步信息")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SyncInfoRow(
                                title: "健康数据",
                                lastSync: "5分钟前",
                                icon: "heart.fill",
                                color: .red
                            )
                            
                            SyncInfoRow(
                                title: "活动数据",
                                lastSync: "10分钟前",
                                icon: "figure.run",
                                color: .green
                            )
                            
                            SyncInfoRow(
                                title: "睡眠数据",
                                lastSync: "1小时前",
                                icon: "moon.fill",
                                color: .purple
                            )
                            
                            Button(action: {
                                syncAllDevices()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("立即同步所有设备")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Device Tips
                    VStack(alignment: .leading, spacing: 15) {
                        Text("设备使用提示")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TipCard(
                                icon: "battery.100",
                                title: "保持设备电量充足",
                                description: "建议设备电量低于20%时及时充电"
                            )
                            
                            TipCard(
                                icon: "arrow.clockwise",
                                title: "定期同步数据",
                                description: "每天至少同步一次以获取准确的健康数据"
                            )
                            
                            TipCard(
                                icon: "lock.shield",
                                title: "保护隐私安全",
                                description: "所有健康数据均经过加密存储"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .padding(.bottom)
            }
            .navigationTitle("设备管理")
            .sheet(isPresented: $showingAddDevice) {
                AddDeviceView()
            }
        }
    }
    
    func toggleConnection(device: HealthDevice) {
        if let index = connectedDevices.firstIndex(where: { $0.id == device.id }) {
            connectedDevices[index].isConnected.toggle()
        }
    }
    
    func syncAllDevices() {
        // Simulate sync
        for index in connectedDevices.indices {
            if connectedDevices[index].isConnected {
                connectedDevices[index].lastSync = Date()
            }
        }
    }
}

struct DeviceStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DeviceCard: View {
    let device: HealthDevice
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Device Icon
            Image(systemName: device.type.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(device.isConnected ? Color.blue : Color.gray)
                .cornerRadius(12)
            
            // Device Info
            VStack(alignment: .leading, spacing: 6) {
                Text(device.name)
                    .font(.headline)
                
                HStack(spacing: 15) {
                    // Battery
                    HStack(spacing: 4) {
                        Image(systemName: "battery.75")
                            .font(.caption)
                        Text("\(device.batteryLevel)%")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Last Sync
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                        Text(device.lastSync, style: .relative)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Connection Toggle
            Toggle("", isOn: Binding(
                get: { device.isConnected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct SyncInfoRow: View {
    let title: String
    let lastSync: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(lastSync)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct AddDeviceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("扫描附近设备")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("请确保设备已开启蓝牙并处于配对模式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加设备")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Models
struct HealthDevice: Identifiable {
    let id = UUID()
    let name: String
    let type: DeviceType
    var isConnected: Bool
    var batteryLevel: Int
    var lastSync: Date
}

enum DeviceType {
    case smartWatch
    case fitnessBand
    case scale
    case heartRateMonitor
    
    var icon: String {
        switch self {
        case .smartWatch: return "applewatch"
        case .fitnessBand: return "wristwatch"
        case .scale: return "scalemass"
        case .heartRateMonitor: return "heart.circle"
        }
    }
}

#Preview {
    DeviceManagementView()
}
