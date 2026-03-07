//
//  AIAdviceView.swift
//  Aura
//
//  AI 建议 Tab（PRD Tab 4）- 参考 Tab4-AI Advice.png
//

import SwiftUI
import UIKit
import FirebaseAuth

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
                title: remainingSteps > 0 ? "Move Goal" : "Move Goal Closed",
                description: remainingSteps > 0
                    ? "You have \(remainingSteps.formatted()) steps left to hit today's goal."
                    : "You've already reached today's step target.",
                urgency: remainingSteps > 0 ? "TODAY" : nil,
                iconName: "figure.walk",
                iconColor: Color.auraGreen,
                cardColor: Color.auraGreenLight
            ),
            InsightCard(
                title: "Calorie Balance",
                description: remainingCalories > 0
                    ? "\(remainingCalories.formatted()) kcal remaining in today's intake target."
                    : "You've reached today's calorie target. Keep dinner on the lighter side.",
                urgency: remainingCalories > 300 ? nil : "WATCH",
                iconName: "flame.fill",
                iconColor: Color.orange,
                cardColor: Color.orange.opacity(0.15)
            )
        ]

        if let heartRate {
            cards.append(
                InsightCard(
                    title: "Heart Rate Update",
                    description: "Latest reading is \(heartRate) BPM. Use it as today's current cardio baseline.",
                    urgency: heartRate > 105 ? "CHECK" : nil,
                    iconName: "heart.fill",
                    iconColor: Color.auraRed,
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
            .background(Color.white)
            .task {
                await healthDataManager.refreshIfNeeded()
            }
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
                Text("\(insightCards.count) ALERTS")
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
            if !streamingText.isEmpty {
                aiBubble(ChatMessage(text: streamingText + "▌", isUser: false, timestamp: Date()))
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
                    if isWaitingForAI {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.auraGreen.opacity(0.7))
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.auraGreen)
                            .clipShape(Circle())
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
