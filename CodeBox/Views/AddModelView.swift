import SwiftUI
import SwiftData

struct AddModelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingModel: AIModel? = nil

    @State private var displayName = ""
    @State private var providerRaw = AIProvider.openAI.rawValue
    @State private var modelId = AIProvider.openAI.defaultModel
    @State private var apiKey = ""
    @State private var baseURL = AIProvider.openAI.defaultBaseURL

    private var isEditing: Bool { editingModel != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("显示名称", text: $displayName)
                    Picker("服务商", selection: $providerRaw) {
                        ForEach(AIProvider.allCases, id: \.rawValue) { p in
                            Text(p.rawValue).tag(p.rawValue)
                        }
                    }
                    .onChange(of: providerRaw) { _, newValue in
                        guard let p = AIProvider(rawValue: newValue) else { return }
                        if !isEditing {
                            modelId = p.defaultModel
                            baseURL = p.defaultBaseURL
                        }
                        if displayName.isEmpty { displayName = p.rawValue }
                    }
                }

                Section("模型配置") {
                    TextField("模型 ID", text: $modelId)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle(isEditing ? "编辑模型" : "新增模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(displayName.isEmpty || modelId.isEmpty)
                }
            }
            .onAppear { prefill() }
        }
    }

    private func prefill() {
        guard let m = editingModel else { return }
        displayName = m.displayName
        providerRaw = m.provider
        modelId = m.modelId
        apiKey = m.apiKey
        baseURL = m.baseURL
    }

    private func save() {
        if let m = editingModel {
            m.displayName = displayName
            m.provider = providerRaw
            m.modelId = modelId
            m.apiKey = apiKey
            m.baseURL = baseURL
        } else {
            modelContext.insert(AIModel(
                displayName: displayName,
                provider: providerRaw,
                modelId: modelId,
                apiKey: apiKey,
                baseURL: baseURL
            ))
        }
        dismiss()
    }
}

