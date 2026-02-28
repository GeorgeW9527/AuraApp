//
//  AIAdviceView.swift
//  Aura
//
//  AI 建议 Tab（PRD Tab 4）- 参考 Tab4-AI Advice.png
//

import SwiftUI
import UIKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct InsightCard: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let urgency: String?
    let iconName: String
    let iconColor: Color
    let cardColor: Color
}

struct AIAdviceView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "Hello! I've analyzed your health data for the last 24 hours. You're doing great with your fiber intake, but I noticed your sleep quality was slightly lower than usual. Would you like some tips for a better night's rest?",
            isUser: false,
            timestamp: Calendar.current.date(bySettingHour: 10, minute: 42, second: 0, of: Date()) ?? Date()
        ),
        ChatMessage(
            text: "Yes, please. I've been feeling a bit sluggish this morning too.",
            isUser: true,
            timestamp: Date()
        )
    ]

    private let insightCards: [InsightCard] = [
        InsightCard(
            title: "Hydration Needed",
            description: "Drink 250ml now to stay on track with your target.",
            urgency: "IMMEDIATE",
            iconName: "drop.fill",
            iconColor: Color(red: 0.2, green: 0.5, blue: 0.9),
            cardColor: Color(red: 0.9, green: 0.95, blue: 1.0)
        ),
        InsightCard(
            title: "Nutrition !",
            description: "Your protein intake is optimal today. Keep it up!",
            urgency: nil,
            iconName: "fork.knife",
            iconColor: Color.auraGreen,
            cardColor: Color.auraGreenLight
        )
    ]

    private let quickActions = ["Analyze breakfast", "Symptom checker", "Supplements"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        dailyInsightsSection
                        chatSection
                    }
                    .padding(.bottom, 120)
                }
                inputSection
            }
            .background(Color.white)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                ProfileHeaderAvatarView(size: 44)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("AI Advice")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.auraGreen)
            Spacer()
            NavigationLink(destination: DeviceManagementView()) {
                Circle()
                    .fill(Color(white: 0.92))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "applewatch").font(.title3).foregroundColor(Color.auraGrayDark))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Daily Insights

    private var dailyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DAILY INSIGHTS")
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                Spacer()
                Text("3 ALERTS")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.auraGreen)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insightCards) { card in
                        insightCardView(card)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func insightCardView(_ card: InsightCard) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.iconName)
                .font(.title2)
                .foregroundColor(card.iconColor)
            VStack(alignment: .leading, spacing: 6) {
                if let urgency = card.urgency {
                    Text(urgency)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(card.iconColor)
                }
                Text(card.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.auraGrayDark)
                Text(card.description)
                    .font(.caption)
                    .foregroundColor(Color.auraGrayLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 280)
        .background(card.cardColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(card.iconColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Chat

    private var chatSection: some View {
        VStack(spacing: 16) {
            ForEach(messages) { msg in
                if msg.isUser {
                    userBubble(msg)
                } else {
                    aiBubble(msg)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func aiBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.auraGreen)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "sparkles").font(.body).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 6) {
                Text(msg.text)
                    .font(.subheadline)
                    .foregroundColor(Color.auraGrayDark)
                    .fixedSize(horizontal: false, vertical: true)
                Text(msg.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(Color.auraGrayLight)
            }
            .padding(12)
            .background(Color(white: 0.94))
            .cornerRadius(14)
            .cornerRadius(4, corners: .topRight)
            Spacer(minLength: 60)
        }
    }

    private func userBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Spacer(minLength: 60)
            VStack(alignment: .trailing, spacing: 6) {
                Text(msg.text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.auraGreen)
            .cornerRadius(14)
            .cornerRadius(4, corners: .topLeft)
        }
    }

    // MARK: - Quick Actions + Input

    private var inputSection: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickActions, id: \.self) { action in
                        Button {
                            inputText = action
                        } label: {
                            Text(action)
                                .font(.caption)
                                .foregroundColor(Color.auraGrayDark)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(white: 0.95))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.auraGrayLight.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 12) {
                HStack {
                    TextField("Ask me anything...", text: $inputText)
                        .font(.subheadline)
                    Button {} label: {
                        Image(systemName: "mic.fill")
                            .font(.body)
                            .foregroundColor(Color.auraGrayLight)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(white: 0.95))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.auraGrayLight.opacity(0.4), lineWidth: 1)
                )

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.auraGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color.white)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let msg = ChatMessage(text: text, isUser: true, timestamp: Date())
        messages.append(msg)
        inputText = ""
        // TODO: 调用 AI 接口获取回复，目前添加占位回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append(ChatMessage(
                text: "I'll help you with that. Based on your health profile, here are some personalized suggestions...",
                isUser: false,
                timestamp: Date()
            ))
        }
    }
}

// MARK: - 单角圆角扩展

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    AIAdviceView()
}
