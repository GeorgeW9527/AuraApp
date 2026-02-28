//
//  AIChatService.swift
//  Aura
//
//  AI 对话服务 - 复用 Tab2 的 APIConfig（endpoint、key、model）
//

import Foundation

struct AIChatService {
    static let shared = AIChatService()

    private init() {}

    /// 流式发送对话，每收到一块内容调用 onChunk
    func sendChatStream(messages: [(role: String, content: String)], onChunk: @escaping (String) -> Void) async throws {
        guard let url = URL(string: APIConfig.openAIEndpoint) else {
            throw NSError(domain: "AIChatError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "无效的API端点"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("Aura-Health-App/1.0 (iOS 17.0; iPhone)", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 120

        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }
        let requestBody: [String: Any] = [
            "model": APIConfig.openAIModel,
            "messages": apiMessages,
            "max_tokens": 800,
            "temperature": 0.7,
            "stream": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AIChatError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
        }

        guard httpResponse.statusCode == 200 else {
            var errorData = Data()
            for try await byte in bytes { errorData.append(byte) }
            let errorBody = String(data: errorData, encoding: .utf8) ?? ""
            throw NSError(domain: "AIChatError", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "API错误 (\(httpResponse.statusCode)): \(errorBody.prefix(200))"])
        }

        var buffer = ""
        for try await byte in bytes {
            buffer.append(Character(Unicode.Scalar(byte)))
            while let newline = buffer.firstIndex(of: "\n") {
                let line = String(buffer[..<newline])
                buffer = String(buffer[buffer.index(after: newline)...])
                if line.hasPrefix("data: ") {
                    let jsonStr = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                    if jsonStr == "[DONE]" { continue }
                    if !jsonStr.isEmpty, let content = parseSSEDelta(jsonStr) {
                        onChunk(content)
                    }
                }
            }
        }
        if !buffer.isEmpty, buffer.hasPrefix("data: ") {
            let jsonStr = String(buffer.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            if jsonStr != "[DONE]", !jsonStr.isEmpty, let content = parseSSEDelta(jsonStr) {
                onChunk(content)
            }
        }
    }

    private func parseSSEDelta(_ jsonStr: String) -> String? {
        guard let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let delta = first["delta"] as? [String: Any],
              let content = delta["content"] as? String else { return nil }
        return content
    }

    /// 非流式发送（兼容保留）
    func sendChat(messages: [(role: String, content: String)]) async throws -> String {
        var fullResponse = ""
        try await sendChatStream(messages: messages) { chunk in
            fullResponse += chunk
        }
        return fullResponse.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
