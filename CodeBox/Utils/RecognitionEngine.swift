import Foundation

struct RecognitionResult {
    var type: ItemType
    var platform: String?
    var extractedContent: String
    var stationName: String? = nil
    var stationAddress: String? = nil
}

struct RecognitionEngine {
    static let shared = RecognitionEngine()

    let pickupRegex = try! NSRegularExpression(pattern: "(菜鸟|丰巢|顺丰|中通|圆通|申通|韵达|极兔)[^0-9a-zA-Z]*([a-zA-Z0-9-]{4,10})")
    let verificationRegex = try! NSRegularExpression(pattern: "(验证码|校验码|动态码|code)[^0-9]*([0-9]{4,6})", options: .caseInsensitive)
    let pureDigitsRegex = try! NSRegularExpression(pattern: "^\\s*([0-9]{4,6})\\s*$")

    func recognize(text: String) -> RecognitionResult? {
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        if let match = pickupRegex.firstMatch(in: text, options: [], range: fullRange) {
            let platform = nsString.substring(with: match.range(at: 1))
            let code = nsString.substring(with: match.range(at: 2))
            return RecognitionResult(type: .pickupCode, platform: platform, extractedContent: code)
        }

        if let match = verificationRegex.firstMatch(in: text, options: [], range: fullRange) {
            let code = nsString.substring(with: match.range(at: 2))
            return RecognitionResult(type: .verificationCode, platform: nil, extractedContent: code)
        }

        if let match = pureDigitsRegex.firstMatch(in: text, options: [], range: fullRange) {
            let code = nsString.substring(with: match.range(at: 1))
            return RecognitionResult(type: .verificationCode, platform: nil, extractedContent: code)
        }

        return nil
    }
}
