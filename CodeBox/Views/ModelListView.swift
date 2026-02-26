import SwiftUI
import SwiftData

struct ModelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIModel.createdAt) private var models: [AIModel]
    @AppStorage("active_model_id") private var activeModelId: String = ""
    @State private var showingAddModel = false
    @State private var editingModel: AIModel? = nil
    @State private var actionModel: AIModel? = nil

    var body: some View {
        Group {
            if models.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
            } else {
                List {
                    ForEach(models) { model in
                        ModelRowView(model: model, isActive: model.id.uuidString == activeModelId)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeModelId = activeModelId == model.id.uuidString ? "" : model.id.uuidString
                            }
                            .onLongPressGesture { actionModel = model }
                    }
                    .onDelete { indexSet in
                        for index in indexSet { modelContext.delete(models[index]) }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("模型管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddModel = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddModel) {
            AddModelView()
        }
        .sheet(item: $editingModel) { model in
            AddModelView(editingModel: model)
        }
        .confirmationDialog(
            actionModel?.displayName ?? "",
            isPresented: Binding(get: { actionModel != nil }, set: { if !$0 { actionModel = nil } }),
            titleVisibility: .visible
        ) {
            Button("编辑") { editingModel = actionModel }
            Button("删除", role: .destructive) {
                if let m = actionModel { modelContext.delete(m) }
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.system(size: 52))
                .foregroundColor(.gray.opacity(0.4))
            Text("暂无模型配置")
                .foregroundColor(.secondary)
            Button("添加模型") { showingAddModel = true }
                .buttonStyle(.borderedProminent)
        }
    }
}
