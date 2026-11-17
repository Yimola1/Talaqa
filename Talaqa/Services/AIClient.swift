import Foundation
import Security

struct ChatTurn {
    let role: String   // "user" or "assistant"
    let content: String
}

enum AIError: LocalizedError {
    case notConfigured
    case http(Int, String)
    case refusal
    case empty
    case decoding

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "المعلّم الذكي غير مفعّل. أضف رابط الخادم أو مفتاح API من الإعدادات."
        case .http(let code, let msg): return "خطأ من الخادم (\(code)): \(msg)"
        case .refusal: return "لم يتمكّن المعلّم من الرد على هذه الرسالة. جرّب صياغة أخرى."
        case .empty: return "وصل رد فارغ. حاول مرة أخرى."
        case .decoding: return "تعذّرت قراءة الرد."
        }
    }
}

/// Minimal Claude Messages API client over URLSession.
/// Two modes:
///  • Proxy (recommended for distribution): the app posts to your own server,
///    which adds the API key. See /server in the repository.
///  • Personal key: the key is stored in the iOS Keychain on this device only.
final class AIClient {
    static let shared = AIClient()

    struct ModelOption: Identifiable {
        let id: String
        let title: String
    }

    static let models: [ModelOption] = [
        ModelOption(id: "claude-opus-5-5", title: "Claude Opus 5.5 (الأذكى)"),
        ModelOption(id: "claude-sonnet-5-5", title: "Claude Sonnet 5.5 (أسرع)"),
        ModelOption(id: "claude-haiku-5-5", title: "Claude Haiku 5.5 (الأرخص)")
    ]
    static let defaultModel = "claude-opus-5-5"
    static let keychainKey = "anthropicApiKey"
    private static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let modelsWithFallback: Set<String> = ["claude-opus-5-5", "claude-sonnet-5-5"]

    var proxyURL: URL? {
        let raw = (UserDefaults.standard.string(forKey: "aiProxyURL") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let url = URL(string: raw), url.scheme?.hasPrefix("http") == true else { return nil }
        return url
    }

    var apiKey: String? {
        guard let key = Keychain.load(Self.keychainKey), !key.isEmpty else { return nil }
        return key
    }

    var model: String {
        let m = UserDefaults.standard.string(forKey: "aiModel") ?? ""
        return m.isEmpty ? Self.defaultModel : m
    }

    var isConfigured: Bool { proxyURL != nil || apiKey != nil }

    func send(system: String, messages: [ChatTurn], maxTokens: Int = 4000,
              effort: String = "low") async throws -> String {
        var request: URLRequest
        if let proxy = proxyURL {
            request = URLRequest(url: proxy)
            let token = UserDefaults.standard.string(forKey: "aiAppToken") ?? ""
            if !token.isEmpty { request.setValue(token, forHTTPHeaderField: "x-app-token") }
        } else if let key = apiKey {
            request = URLRequest(url: Self.apiURL)
            request.setValue(key, forHTTPHeaderField: "x-api-key")
        } else {
            throw AIError.notConfigured
        }

        let model = self.model
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")

        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "output_config": ["effort": effort]
        ]
        if Self.modelsWithFallback.contains(model) {
            // If a safety classifier declines, the API retries on a suitable model.
            request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
            body["fallbacks"] = "default"
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        guard (200..<300).contains(status) else {
            let message = ((json?["error"] as? [String: Any])?["message"] as? String)
                ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.http(status, message)
        }
        guard let json else { throw AIError.decoding }
        if (json["stop_reason"] as? String) == "refusal" { throw AIError.refusal }

        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks
            .filter { ($0["type"] as? String) == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw AIError.empty }
        return text
    }
}

// MARK: - Keychain

enum Keychain {
    static func save(_ value: String, for key: String) {
        delete(key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
