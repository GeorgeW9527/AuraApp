//
//  AIAdviceView.swift
//  Aura
//
//  AI 建议 Tab（PRD Tab 4）- 参考 Tab4-AI Advice.png
//

import SwiftUI
import UIKit
import FirebaseAuth

// MARK: - Tab4 AI Advice Color Palette (match tab4.png)
private enum AIPalette {
    static let deepGreen       = Color(red: 0.11, green: 0.32, blue: 0.22)
    static let limeGreen       = Color(red: 0.84, green: 0.91, blue: 0.34)
    static let blueCardBg      = Color(red: 0.55, green: 0.65, blue: 0.95)
    static let creamCardBg     = Color(red: 0.95, green: 0.97, blue: 0.88)
    static let primaryText     = Color(red: 0.12, green: 0.16, blue: 0.13)
    static let secondaryText   = Color(red: 0.55, green: 0.58, blue: 0.52)
    static let chatBubbleBg    = Color(red: 0.94, green: 0.96, blue: 0.93)
    static let alertBadgeBg    = Color(red: 0.90, green: 0.93, blue: 0.88)
}

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
    @EnvironmentObject var healthDataManager: HealthDataManager
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "Hello! I'm your Aura health assistant. I can help with nutrition, exercise, sleep, and general wellness. What would you like to know?",
            isUser: false,
            timestamp: Date()
        )
    ]
    @State private var isWaitingForAI = false
    @State private var streamingText = ""
    @State private var errorMessage: String?

    private let quickActions = ["Analyze breakfast", "Symptom checker", "Supplements"]
    private let localStorage = LocalStorageManager.shared

    private var userId: String {
        authViewModel.currentUser?.uid ?? authViewModel.userProfile?.userId ?? ""
    }

    private var todayNutritionRecords: [LocalStorageManager.LocalNutritionRecord] {
        guard !userId.isEmpty else { return [] }
        return localStorage.loadNutritionRecords(userId: userId).filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: Date())
        }
    }

    private var todayCalories: Int {
        todayNutritionRecords.reduce(0) { $0 + $1.calories }
    }

    private var calorieGoal: Int {
        Int((authViewModel.userProfile?.dailyCalorieGoal ?? 1800).rounded())
    }

    private var insightCards: [InsightCard] {
        let stepGoal = 10_000
        let remainingSteps = max(0, stepGoal - healthDataManager.todayStepCount)
        let remainingCalories = max(0, calorieGoal - todayCalories)
        let heartRate = healthDataManager.latestHeartRate ?? healthDataManager.restingHeartRate

        var cards: [InsightCard] = [
            InsightCard(
                title: remainingSteps > 0 ? "Hydration Needed" : "Hydration On Track",
                description: remainingSteps > 0
                    ? "Drink 250ml now to stay on track with your target."
                    : "Great job! You've met your hydration goal for today.",
                urgency: remainingSteps > 0 ? "IMMEDIATE" : nil,
                iconName: "drop.fill",
                iconColor: AIPalette.blueCardBg,
                cardColor: AIPalette.blueCardBg.opacity(0.25)
            ),
            InsightCard(
                title: "Nutrition Status",
                description: remainingCalories > 0
                    ? "Your protein intake is on point. Keep it up!"
                    : "You've reached today's calorie target. Great work!",
                urgency: nil,
                iconName: "fork.knife",
                iconColor: AIPalette.limeGreen,
                cardColor: AIPalette.creamCardBg
            )
        ]

        if let heartRate {
            cards.append(
                InsightCard(
                    title: "Heart Rate Update",
                    description: "Latest reading is \(heartRate) BPM. Use it as today's current cardio baseline.",
                    urgency: heartRate > 105 ? "CHECK" : nil,
                    iconName: "heart.fill",
                    iconColor: Color(red: 0.95, green: 0.35, blue: 0.35),
                    cardColor: Color(red: 1.0, green: 0.93, blue: 0.95)
                )
            )
        }

        return cards
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            dailyInsightsSection
                            chatSection
                            Color.clear
                                .frame(height: 1)
                                .id("chatBottom")
                        }
                        .padding(.bottom, 120)
                    }
                    .onChange(of: messages.count) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("chatBottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: streamingText) {
                        proxy.scrollTo("chatBottom", anchor: .bottom)
                    }
                }
                inputSection
            }
            .background(Color(red: 0.97, green: 0.98, blue: 0.96))
            .task {
                await healthDataManager.refreshIfNeeded()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            NavigationLink(destination: UserProfileView()) {
                Circle()
                    .fill(Color(red: 0.92, green: 0.94, blue: 0.90))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AIPalette.deepGreen)
                    }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("AI ADVICE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AIPalette.deepGreen)
            Spacer()
            NavigationLink(destination: DeviceManagementView()) {
                Circle()
                    .stroke(Color(red: 0.88, green: 0.90, blue: 0.86), lineWidth: 1)
                    .background(Circle().fill(Color.white))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "applewatch")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AIPalette.deepGreen)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Daily Insights

    private var dailyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DAILY INSIGHTS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(AIPalette.secondaryText)
                Spacer()
                Text("\(insightCards.count) ALERTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AIPalette.deepGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AIPalette.alertBadgeBg)
                    .cornerRadius(16)
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
            // Icon in circular background
            Circle()
                .fill(card.iconColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: card.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(card.iconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                if let urgency = card.urgency {
                    HStack {
                        Spacer()
                        Text(urgency)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(AIPalette.deepGreen)
                    }
                }
                Text(card.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AIPalette.deepGreen)
                Text(card.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AIPalette.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(width: 280, height: 110)
        .background(card.cardColor)
        .cornerRadius(16)
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
            if !streamingText.isEmpty {
                aiBubble(ChatMessage(text: streamingText + "▌", isUser: false, timestamp: Date()))
            }
        }
        .padding(.horizontal, 16)
    }

    private func aiBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // AI Avatar
            Circle()
                .fill(AIPalette.deepGreen)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(msg.text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AIPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(msg.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(AIPalette.secondaryText)
                    .padding(.top, 2)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .cornerRadius(4, corners: .topLeft)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

            Spacer(minLength: 40)
        }
    }

    private func userBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 4) {
                Text(msg.text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AIPalette.deepGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(AIPalette.limeGreen)
            .cornerRadius(16)
            .cornerRadius(4, corners: .topRight)
        }
    }

    // MARK: - Quick Actions + Input

    private var inputSection: some View {
        VStack(spacing: 12) {
            // Quick Actions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickActions, id: \.self) { action in
                        Button {
                            inputText = action
                        } label: {
                            Text(action)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AIPalette.primaryText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 0.88, green: 0.90, blue: 0.86), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }

            // Input Field
            HStack(spacing: 12) {
                HStack {
                    TextField("Ask me anything...", text: $inputText)
                        .font(.system(size: 14))
                        .foregroundColor(AIPalette.primaryText)
                    Button {} label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AIPalette.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(red: 0.88, green: 0.90, blue: 0.86), lineWidth: 1)
                )

                // Send Button
                Button {
                    sendMessage()
                } label: {
                    if isWaitingForAI {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 48, height: 48)
                            .background(AIPalette.deepGreen.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(AIPalette.deepGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .buttonStyle(.plain)
                .disabled(isWaitingForAI)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let userMsg = ChatMessage(text: text, isUser: true, timestamp: Date())
        messages.append(userMsg)
        inputText = ""
        errorMessage = nil
        isWaitingForAI = true

        Task {
            do {
                streamingText = ""
                let apiMessages = buildAPIMessages()
                try await AIChatService.shared.sendChatStream(messages: apiMessages) { chunk in
                    Task { @MainActor in
                        streamingText += chunk
                    }
                }
                await MainActor.run {
                    let fullText = streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !fullText.isEmpty {
                        messages.append(ChatMessage(text: fullText, isUser: false, timestamp: Date()))
                    }
                    streamingText = ""
                    isWaitingForAI = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    streamingText = ""
                    isWaitingForAI = false
                }
            }
        }
    }

    private func buildAPIMessages() -> [(role: String, content: String)] {
        var result: [(role: String, content: String)] = [
            ("system", """
                You are the Aura health assistant. Provide concise, practical health and wellness advice.
                Focus on nutrition, exercise, sleep, and general wellness. Respond in the same language as the user.
                """)
        ]
        let recent = messages.suffix(20)
        for msg in recent {
            result.append((msg.isUser ? "user" : "assistant", msg.text))
        }
        return result
    }
}

// MARK: - Rounded Corner Extension

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
        .environmentObject(AuthViewModel())
        .environmentObject(HealthDataManager())
}
