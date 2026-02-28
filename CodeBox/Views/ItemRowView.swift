import SwiftUI
import SwiftData

struct ItemRowView: View {
    @Bindable var item: ClipboardItem

    var body: some View {
        if item.isUsed {
            completedCard
        } else {
            pendingCard
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
                        .fill(Color(red: 0.95, green: 0.75, blue: 0.35)) // 黄色
                        .frame(width: 40, height: 40)
                    Image(systemName: "box.truck")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                
                Spacer()
                
                // 右侧状态与操作圈
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("待取")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        withAnimation {
                            item.isUsed = true
                            item.usedAt = Date()
                        }
                    }) {
                        Circle()
                            .stroke(Color.secondary, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // 中间：大字号取件码
            Text(item.content)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            // 底部：地址和图标
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
                    .foregroundColor(.primary)
                Text(item.sourcePlatform ?? "快递")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 右侧内容
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.stationAddress ?? item.stationName ?? "未知地址")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text((item.usedAt ?? item.createdAt).formatted(.dateTime.month().day().locale(Locale(identifier: "zh_CN"))))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ClipboardItem
    
    // 渐变背景色
    private let bgGradient = LinearGradient(
        colors: [
            Color(red: 0.18, green: 0.38, blue: 0.52), // 顶部偏蓝
            Color(red: 0.35, green: 0.60, blue: 0.75), // 中间浅蓝
            Color(uiColor: .systemGroupedBackground) // 底部适配系统背景色
        ],
        startPoint: .top,
        endPoint: UnitPoint(x: 0.5, y: 0.6)
    )

    var body: some View {
        ZStack(alignment: .top) {
            bgGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部信息区
                VStack(spacing: 16) {
                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.45, green: 0.73, blue: 0.90))
                            .frame(width: 80, height: 80)
                        
                        // 占位图标，如果是菜鸟使用鸟图标，否则使用通用图标
                        Image(systemName: item.sourcePlatform?.contains("菜鸟") == true ? "bird" : "shippingbox")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // 取件码
                    Text(item.content)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 平台和时间
                    HStack(spacing: 6) {
                        Text(item.sourcePlatform ?? "快递")
                        Text("·")
                        Text(item.createdAt.formatted(.dateTime.month().day().locale(Locale(identifier: "zh_CN"))))
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.8))
                }
                .padding(.bottom, 40)
                
                // 底部信息列表区
                ScrollView {
                    VStack(spacing: 16) {
                        // 所属账户
                        DetailInfoRow(title: "所属账户", content: "默认账户", hasDisclosure: true, icon: "person.circle.fill")
                        
                        // 取件地点
                        if let address = item.stationAddress ?? item.stationName {
                            DetailInfoRow(title: "取件地点", content: address)
                        }
                        
                        // 原始短信内容
                        if let original = item.originalContent, !original.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(original)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineSpacing(4)
                                    .padding(16)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // 到件时间 (创建时间)
                        DetailInfoRow(title: "到件时间", content: item.createdAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                        
                        // 取件时间 (如果已取)
                        if item.isUsed, let usedAt = item.usedAt {
                            DetailInfoRow(title: "取件时间", content: usedAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                        }
                        
                        Spacer().frame(height: 40)
                        
                        // 底部按钮区
                        VStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    item.isUsed.toggle()
                                    if item.isUsed {
                                        item.usedAt = Date()
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: item.isUsed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                    Text(item.isUsed ? "标记为待取" : "标记为已取")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.85, green: 0.55, blue: 0.20)) // 橙色
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
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
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 编辑功能预留
                }) {
                    Text("编辑")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
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
