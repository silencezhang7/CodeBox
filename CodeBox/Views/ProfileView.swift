import SwiftUI
import SwiftData
import UserNotifications

struct ProfileView: View {
    @AppStorage("app_theme") private var themeRaw: String = AppTheme.system.rawValue
    @AppStorage("pickup_notification") private var pickupNotification: Bool = true
    @Query(sort: \AIModel.createdAt) private var models: [AIModel]
    @AppStorage("active_model_id") private var activeModelId: String = ""

    private var activeModelName: String {
        models.first { $0.id.uuidString == activeModelId }?.displayName ?? "未配置"
    }

    var body: some View {
        NavigationStack {
            List {
                // 头像
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                            Text("用户")
                                .font(.headline)
                        }
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                // 外观
                Section("外观") {
                    Picker(selection: $themeRaw) {
                        ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                            Label(theme.label, systemImage: theme.icon).tag(theme.rawValue)
                        }
                    } label: {
                        Label("主题", systemImage: "paintbrush")
                    }
                    .pickerStyle(.menu)
                }
                .listRowBackground(Color.clear.background(.regularMaterial))

                // 通知
                Section("通知") {
                    Toggle(isOn: $pickupNotification) {
                        Label("待取件提醒", systemImage: "bell")
                    }
                    .onChange(of: pickupNotification) { _, enabled in
                        if enabled { requestNotificationPermission() }
                    }
                }
                .listRowBackground(Color.clear.background(.regularMaterial))

                // 模型管理
                Section("AI") {
                    NavigationLink {
                        ModelListView()
                    } label: {
                        HStack {
                            Label("模型管理", systemImage: "cpu")
                            Spacer()
                            Text(activeModelName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.clear.background(.regularMaterial))
            }
            .navigationTitle("")
            .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
            .scrollContentBackground(.hidden)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
