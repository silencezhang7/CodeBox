import SwiftUI
import SwiftData

struct EditClipboardItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var item: ClipboardItem
    
    @State private var content: String
        @State private var sourcePlatform: String
        @State private var stationName: String
        @State private var stationAddress: String
        @State private var reminderType: ReminderType
        @State private var reminderTime: Date
    
        init(item: ClipboardItem) {
        self.item = item
        _content = State(initialValue: item.content)
        _sourcePlatform = State(initialValue: item.sourcePlatform ?? "")
        _stationName = State(initialValue: item.stationName ?? "")
        _stationAddress = State(initialValue: item.stationAddress ?? "")
        _reminderType = State(initialValue: item.reminderType)
        _reminderTime = State(initialValue: item.reminderTime ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                customNavBar
                
                ScrollView {
                    VStack(spacing: 24) {
                        editInfoSection
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
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
            
            Text("编辑\(item.type.rawValue)")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Button {
                save()
            } label: {
                Text("保存")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
    
    private var editInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: item.type == .verificationCode ? "message.fill" : "shippingbox.fill")
                Text(item.type == .verificationCode ? "验证码信息" : "取件信息").font(.headline).fontWeight(.bold)
            }

            VStack(spacing: 0) {
                if item.type == .verificationCode {
                    EditInfoRow(icon: "number", title: "验证码", text: $content, placeholder: "如: 123456")
                    Divider().padding(.leading, 40)
                    EditInfoRow(icon: "building.2", title: "发送机构", text: $sourcePlatform, placeholder: "如: 支付宝")
                } else {
                    EditInfoRow(icon: "number", title: "取件码", text: $content, placeholder: "如: 1-1-1")
                    
                    if item.type == .pickupCode {
                        Divider().padding(.leading, 40)
                        EditInfoRow(icon: "box.truck", title: "快递公司", text: $sourcePlatform, placeholder: "如: 中通快递")
                        
                        Divider().padding(.leading, 40)
                        EditInfoRow(icon: "building.2", title: "驿站名称", text: $stationName, placeholder: "如: 菜鸟驿站")
                        
                        Divider().padding(.leading, 40)
                        EditInfoRow(icon: "mappin.and.ellipse", title: "详细地址", text: $stationAddress, placeholder: "驿站的详细地址")
                        
                        Divider().padding(.leading, 40)
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("提醒方式")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 65, alignment: .leading)
                            Picker("", selection: $reminderType) {
                                ForEach(ReminderType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        if reminderType == .exactTime {
                            Divider().padding(.leading, 40)
                            HStack(spacing: 12) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                Text("提醒时间")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 65, alignment: .leading)
                                DatePicker("", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
        }
    }
    
    private func save() {
        item.content = content
                item.sourcePlatform = sourcePlatform.isEmpty ? nil : sourcePlatform
                item.stationName = stationName.isEmpty ? nil : stationName
                item.stationAddress = stationAddress.isEmpty ? nil : stationAddress
        
                if item.type == .pickupCode {            item.reminderTypeRaw = reminderType.rawValue
            if reminderType == .exactTime {
                item.reminderTime = reminderTime
            } else {
                item.reminderTime = nil
            }
            
            // Reschedule reminder if the item is not used
            if !item.isUsed {
                ReminderManager.shared.scheduleReminder(for: item)
            }
        } else {
            // Update live activity for other types if applicable
            if !item.isUsed {
                ReminderManager.shared.updateLiveActivity(for: item)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

fileprivate struct EditInfoRow: View {
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
