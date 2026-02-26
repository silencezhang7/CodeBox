import Foundation

enum TestState {
    case idle
    case testing
    case success
    case failure(String)
}

struct ModelTestService {
    // 接收值类型参数，避免跨 actor 传递 SwiftData 对象
    static func test(apiKey: String, baseURL: String, provider: String) async -> TestState {
        guard !apiKey.isEmpty else { return .failure("未配置 API Key") }
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") { base = String(base.dropLast()) }
        guard let url = URL(string: "\(base)/models") else { return .failure("Base URL 无效") }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"
        if provider == AIProvider.anthropic.rawValue {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            return (200...299).contains(code) ? .success : .failure("HTTP \(code)")
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
