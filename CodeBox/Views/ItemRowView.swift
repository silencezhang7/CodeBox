import SwiftUI
import SwiftData

struct ItemRowView: View {
    @Bindable var item: ClipboardItem
    @State private var showingQuickReminderEdit = false

    var body: some View {
        if item.isUsed {
            completedCard
        } else {
            pendingCard
                .sheet(isPresented: $showingQuickReminderEdit) {
                    QuickReminderEditView(item: item)
                        .presentationDetents([.medium, .large])
                }
        }
    }

    // MARK: - 待取卡片样式 (深色大卡片 / 浅色适配)
    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶部：图标与状态
            HStack {
                // 左侧平台图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.type == .verificationCode ? Color(red: 0.35, green: 0.60, blue: 0.75) : Color(red: 0.95, green: 0.75, blue: 0.35))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.type == .verificationCode ? "message.fill" : "box.truck")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }

                if item.type == .verificationCode {
                    Text(item.sourcePlatform ?? "未知机构")
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.sourcePlatform ?? "快递取件")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Button(action: { showingQuickReminderEdit = true }) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 10))
                                Text(item.reminderText)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }

                Spacer()

                // 右侧状态与操作圈
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text(item.type == .verificationCode ? "未使用" : "待取")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Button(action: {
                        withAnimation {
                            item.isUsed = true
                            item.usedAt = Date()
                            ReminderManager.shared.removeReminder(for: item)
                        }
                    }) {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            // 中间：大字号取件码/验证码
            Text(item.content)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            // 底部：地址和图标 / 验证码时间信息
            if item.type == .verificationCode {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("创建时间: \(item.createdAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))")
                        if let expiresAt = item.expiresAt {
                            Text("有效时间: \(expiresAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                HStack {
                    Text(item.stationAddress ?? item.stationName ?? "未知地址")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color.secondary.opacity(0.5))
                        .font(.system(size: 24))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 已取卡片样式 (深色横向卡片 / 浅色适配)
    private var completedCard: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.35, green: 0.60, blue: 0.75)) // 蓝色
                    .frame(width: 48, height: 48)
                Image(systemName: item.sourcePlatform?.contains("菜鸟") == true ? "bird" : "shippingbox")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            }

            // 中间内容
            VStack(alignment: .leading, spacing: 6) {
                Text(item.content)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.primary.opacity(0.6))
                    .strikethrough(true, color: Color.primary.opacity(0.6))

                Text(item.type == .verificationCode ? (item.sourcePlatform ?? "未知机构") : (item.stationName ?? item.sourcePlatform ?? "快递取件"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 右侧状态与还原按钮
            VStack(alignment: .trailing, spacing: 8) {
                Text(item.type == .verificationCode ? "已使用" : "已取件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .cornerRadius(8)

                Button(action: {
                    withAnimation {
                        item.isUsed = false
                        item.usedAt = nil
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .opacity(0.8)
    }
}

// MARK: - 独立详情页
struct ItemDetailView: View {
    @Bindable var item: ClipboardItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. 顶部大卡片区
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                    VStack(spacing: 20) {
                        // 平台图标
                        ZStack {
                            Circle()
                                .fill(item.type == .verificationCode ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: item.type == .verificationCode ? "message.fill" : "box.truck.fill")
                                .font(.system(size: 40))
                                .foregroundColor(item.type == .verificationCode ? .blue : .orange)
                        }

                        // 平台名称
                        Text(item.sourcePlatform ?? (item.type == .verificationCode ? "未知机构" : "快递包裹"))
                            .font(.title2)
                            .fontWeight(.semibold)

                        // 核心内容 (取件码 / 验证码)
                        VStack(spacing: 8) {
                            Text(item.type == .verificationCode ? "验证码" : "取件码")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(item.content)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(item.isUsed ? .secondary : .primary)
                                .strikethrough(item.isUsed)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                }

                // 2. 详细信息列表区
                VStack(spacing: 16) {
                    // 状态行
                    HStack {
                        Text("当前状态")
                            .foregroundColor(.primary)
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.isUsed ? Color.secondary : Color.green)
                                .frame(width: 8, height: 8)
                            Text(item.isUsed ? (item.type == .verificationCode ? "已使用" : "已取件") : (item.type == .verificationCode ? "未使用" : "待取件"))
                                .foregroundColor(item.isUsed ? .secondary : .green)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // 如果是取件码，显示驿站信息
                    if item.type == .pickupCode {
                        DetailInfoRow(title: "驿站名称", content: item.stationName ?? "未指定")
                        DetailInfoRow(title: "详细地址", content: item.stationAddress ?? "未指定", hasDisclosure: false, icon: "mappin.circle.fill")
                    }

                    // 创建时间
                    DetailInfoRow(title: "创建时间", content: item.createdAt.formatted(.dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))

                    // 过期时间
                    if let expiresAt = item.expiresAt {
                        DetailInfoRow(title: "有效时间", content: expiresAt.formatted(.dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                    }

                    // 取件时间 (如果已取)
                    if item.isUsed, let usedAt = item.usedAt {
                        DetailInfoRow(title: item.type == .verificationCode ? "收取时间" : "取件时间", content: usedAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                    }

                    Spacer().frame(height: 40)

                    // 底部按钮区
                    VStack(spacing: 16) {
                        Button(action: {
                            withAnimation {
                                item.isUsed.toggle()
                                if item.isUsed {
                                    item.usedAt = Date()
                                    ReminderManager.shared.removeReminder(for: item)
                                } else {
                                    ReminderManager.shared.scheduleReminder(for: item)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: item.isUsed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                Text(item.isUsed ? (item.type == .verificationCode ? "标记为未收取" : "标记为待取") : (item.type == .verificationCode ? "标记为已收取" : "标记为已取"))
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.85, green: 0.55, blue: 0.20)) // 橙色
                            .cornerRadius(12)
                        }

                        Button(action: {
                            ReminderManager.shared.removeReminder(for: item)
                            modelContext.delete(item)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除")
                            }
                            .font(.headline)
                            .foregroundColor(Color.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(uiColor: .systemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("编辑")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEditSheet) {
            EditClipboardItemView(item: item)
                .presentationDetents([.medium, .large])
        }
    }
}

// 辅助信息行组件
struct DetailInfoRow: View {
    var title: String
    var content: String
    var hasDisclosure: Bool = false
    var icon: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                }
                Text(content)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                if hasDisclosure {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct QuickReminderEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: ClipboardItem

    @State private var reminderType: ReminderType
    @State private var reminderTime: Date

    init(item: ClipboardItem) {
        self.item = item
        _reminderType = State(initialValue: item.reminderType)
        _reminderTime = State(initialValue: item.reminderTime ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("提醒设置")) {
                    Picker("提醒方式", selection: $reminderType) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    if reminderType == .exactTime {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("快捷修改")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                }
            }
        }
    }

    private func save() {
        item.reminderTypeRaw = reminderType.rawValue

        if reminderType == .exactTime {
            item.reminderTime = reminderTime
        } else {
            item.reminderTime = nil
        }
        
        if !item.isUsed {
            ReminderManager.shared.scheduleReminder(for: item)
        }
        
        try? modelContext.save()
        dismiss()
    }
}
