import Foundation

struct AIRecognitionResult {
    var type: ItemType
    var code: String
    var platform: String?
    var stationName: String?
    var stationAddress: String?
}

struct AIRecognitionService {
    static func recognize(text: String, model: AIModel) async throws -> AIRecognitionResult {
        guard let url = buildURL(model) else { throw URLError(.badURL) }

        let prompt = """
        请分析以下文本，提取快递/物流/验证码相关信息，严格以JSON格式返回，不要有其他内容：
        {
          "type": "取件码" 或 "验证码" 或 "其他",
          "code": "提取的码（取件码或验证码），无则空字符串",
          "platform": "平台名称（如菜鸟、丰巢、顺丰等），无则null",
          "stationName": "驿站名称，无则null",
          "stationAddress": "驿站地址，无则null"
        }

        文本：\(text)
        """

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request, model: model)
        request.httpBody = try JSONSerialization.data(withJSONObject: buildBody(model: model, prompt: prompt))

        let (data, _) = try await URLSession.shared.data(for: request)
        return try parseResponse(data: data, provider: model.provider, fallback: text)
    }

    // MARK: - Private

    private static func buildURL(_ model: AIModel) -> URL? {
        var base = model.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.hasSuffix("/") { base = String(base.dropLast()) }
        if model.provider == AIProvider.anthropic.rawValue {
            return URL(string: "\(base)/v1/messages")
        }
        return URL(string: "\(base)/chat/completions")
    }

    private static func applyHeaders(_ request: inout URLRequest, model: AIModel) {
        if model.provider == AIProvider.anthropic.rawValue {
            request.setValue(model.apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        } else {
            request.setValue("Bearer \(model.apiKey)", forHTTPHeaderField: "Authorization")
        }
    }

    private static func buildBody(model: AIModel, prompt: String) -> [String: Any] {
        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        if model.provider == AIProvider.anthropic.rawValue {
            return ["model": model.modelId, "max_tokens": 512, "messages": messages]
        }
        return ["model": model.modelId, "messages": messages, "max_tokens": 512]
    }

    private static func parseResponse(data: Data, provider: String, fallback: String) throws -> AIRecognitionResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "AIRecognition", code: -1)
        }

        var rawText = ""
        if provider == AIProvider.anthropic.rawValue {
            rawText = (json["content"] as? [[String: Any]])?.first?["text"] as? String ?? ""
        } else {
            rawText = ((json["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String ?? ""
        }

        let jsonStr = extractJSON(from: rawText)
        guard let jsonData = jsonStr.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "AIRecognition", code: -2)
        }

        let typeStr = result["type"] as? String ?? "其他"
        let code = (result["code"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let itemType: ItemType
        switch typeStr {
        case "取件码": itemType = .pickupCode
        case "验证码": itemType = .verificationCode
        default: itemType = .other
        }

        return AIRecognitionResult(
            type: itemType,
            code: code.isEmpty ? fallback : code,
            platform: result["platform"] as? String,
            stationName: result["stationName"] as? String,
            stationAddress: result["stationAddress"] as? String
        )
    }

    private static func extractJSON(from text: String) -> String {
        // 尝试提取 ```json ... ``` 块
        if let s = text.range(of: "```json\n"), let e = text.range(of: "\n```", range: s.upperBound..<text.endIndex) {
            return String(text[s.upperBound..<e.lowerBound])
        }
        // 提取第一个 { ... } 块
        if let s = text.range(of: "{"), let e = text.range(of: "}", options: .backwards) {
            return String(text[s.lowerBound...e.lowerBound])
        }
        return text
    }
}
