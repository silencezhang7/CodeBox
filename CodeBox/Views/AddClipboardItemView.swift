import SwiftUI
import UIKit
import SwiftData

struct AddClipboardItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AIModel.createdAt) private var models: [AIModel]
    @AppStorage("active_model_id") private var activeModelId: String = ""

    @State private var content: String = ""
    @State private var type: ItemType
    @State private var isRecognizing = false
    @State private var recognizeError: String? = nil
    
    @State private var extractedCode: String = ""
    @State private var detectedPlatform: String? = nil
    @State private var stationName: String? = nil
    @State private var stationAddress: String? = nil

    init(defaultType: ItemType) {
        _type = State(initialValue: defaultType)
    }

    private var activeModel: AIModel? {
        models.first { $0.id.uuidString == activeModelId && !$0.apiKey.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                customNavBar
                
                ScrollView {
                    VStack(spacing: 24) {
                        modelTipCard
                        smsContentSection
                        extractedInfoSection
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - 自定义导航栏
    private var customNavBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("取消")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            Spacer()
            
            Text(type == .pickupCode ? "添加取件码" : "添加\(type.rawValue)")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Button {
                save()
            } label: {
                Text("添加")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRecognizing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - 模型提示卡片
    private var modelTipCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activeModel == nil ? "未配置 AI 模型" : "AI 识别已就绪")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(activeModel == nil ? "配置后可自动提取信息" : "当前使用模型：\(activeModel!.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink {
                ModelListView()
            } label: {
                Text("配置")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.black.opacity(0.04))
        .cornerRadius(16)
    }

    // MARK: - 短信内容区块
    private var smsContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "message.fill")
                Text("短信内容").font(.headline).fontWeight(.bold)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $content)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 120)
                
                if content.isEmpty {
                    Text("请粘贴短信的全部内容，系统将自动识别")
                        .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding(12)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)

            HStack(spacing: 12) {
                Button {
                    fetchClipboard()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("粘贴短信内容")
                    }
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(16)
                }

                Button {
                    runAIRecognize()
                } label: {
                    HStack {
                        if isRecognizing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isRecognizing ? "识别中" : "AI 智能识别")
                    }
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                }
                .disabled(isRecognizing || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || activeModel == nil)
                .opacity((isRecognizing || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || activeModel == nil) ? 0.6 : 1)
            }

            if let err = recognizeError {
                Text(err).font(.caption).foregroundColor(.red)
            }
        }
    }

    // MARK: - 提取信息区块
    private var extractedInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "shippingbox.fill")
                Text("取件信息").font(.headline).fontWeight(.bold)
            }

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("类型")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 65, alignment: .leading)
                    
                    Picker("", selection: $type) {
                        ForEach(ItemType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                Divider().padding(.leading, 40)
                
                InfoRow(icon: "number", title: "取件码", text: $extractedCode, placeholder: "如: 1-1-1")
                
                if type == .pickupCode {
                    Divider().padding(.leading, 40)
                    InfoRow(icon: "box.truck", title: "快递公司", text: Binding(
                        get: { detectedPlatform ?? "" },
                        set: { detectedPlatform = $0.isEmpty ? nil : $0 }
                    ), placeholder: "如: 中通快递")
                    
                    Divider().padding(.leading, 40)
                    InfoRow(icon: "building.2", title: "驿站名称", text: Binding(
                        get: { stationName ?? "" },
                        set: { stationName = $0.isEmpty ? nil : $0 }
                    ), placeholder: "如: 菜鸟驿站")
                    
                    Divider().padding(.leading, 40)
                    InfoRow(icon: "mappin.and.ellipse", title: "详细地址", text: Binding(
                        get: { stationAddress ?? "" },
                        set: { stationAddress = $0.isEmpty ? nil : $0 }
                    ), placeholder: "驿站的详细地址")
                }
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - 辅助方法
    private func fetchClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        content = text
        recognizeError = nil
        applyRegex(text: text)
    }

    private func runAIRecognize() {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let model = activeModel else { return }
        recognizeError = nil
        isRecognizing = true
        Task {
            defer { Task { @MainActor in isRecognizing = false } }
            do {
                let result = try await AIRecognitionService.recognize(text: text, model: model)
                await MainActor.run {
                    type = result.type
                    extractedCode = result.code
                    detectedPlatform = result.platform
                    stationName = result.stationName
                    stationAddress = result.stationAddress
                }
            } catch {
                await MainActor.run {
                    recognizeError = "AI识别失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func applyRegex(text: String) {
        if let result = RecognitionEngine.shared.recognize(text: text) {
            type = result.type
            extractedCode = result.extractedContent
            detectedPlatform = result.platform
        }
    }

    private func save() {
        let finalCode = extractedCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? content : extractedCode
        let expiration = type == .verificationCode
            ? Date().addingTimeInterval(300)
            : Date().addingTimeInterval(86400 * 3)

        let newItem = ClipboardItem(
            content: finalCode,
            originalContent: content,
            typeRaw: type.rawValue,
            sourcePlatform: detectedPlatform,
            stationName: stationName,
            stationAddress: stationAddress,
            expiresAt: expiration
        )
        modelContext.insert(newItem)
        dismiss()
    }
}

fileprivate struct InfoRow: View {
    var icon: String
    var title: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .leading)
            
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
