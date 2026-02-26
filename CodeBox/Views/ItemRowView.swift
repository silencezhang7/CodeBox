import SwiftUI
import UIKit

struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct ItemRowView: View {
    @Bindable var item: ClipboardItem
    @State private var showingDetails = false

    var body: some View {
        frontCard
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .onTapGesture {
                showingDetails = true
            }
            .sheet(isPresented: $showingDetails) {
                NavigationStack {
                    ScrollView {
                        backCard
                            .padding()
                    }
                    .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingDetails = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
    }

    // MARK: - 正面
    private var frontCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左侧 Logo
            VStack {
                Text(item.sourcePlatform?.prefix(4) ?? "快递")
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.top, 4)

            // 右侧内容
            VStack(alignment: .leading, spacing: 8) {
                // 第一行：平台、标签、时间
                HStack(alignment: .center) {
                    Text(item.sourcePlatform ?? (item.typeRaw == "验证码" ? "短信" : "未知"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(item.typeRaw)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())

                    Spacer()

                    Text(item.createdAt.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 第二行：地址
                if let addr = item.stationAddress {
                    Text(addr)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // 虚线分割线
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
                    .padding(.vertical, 4)

                // 第三行：取件码和操作按钮
                HStack {
                    Text(item.content)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(item.isUsed ? Color(uiColor: .systemGray2) : .primary)
                        .strikethrough(item.isUsed, color: Color(uiColor: .systemGray2))

                    Spacer()

                    Button {
                        UIPasteboard.general.string = item.content
                        withAnimation {
                            item.isUsed.toggle()
                        }
                    } label: {
                        if item.isUsed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.green)
                        } else {
                            Circle()
                                .stroke(Color.blue, lineWidth: 1.5)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }

    // MARK: - 背面
    private var backCard: some View {
        VStack(spacing: 20) {
            
            // 已完成状态顶部横幅
            if item.isUsed {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("已完成取件")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("完成于 \(item.createdAt.formatted(.dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.bottom, 8)
            }

            // 主卡片
            VStack(alignment: .leading, spacing: 0) {
                // 顶部橙色条
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)

                VStack(alignment: .leading, spacing: 16) {
                    // 头部：Logo 和 名称
                    HStack(spacing: 12) {
                        Text(item.sourcePlatform?.prefix(4) ?? "快递")
                            .font(.system(size: 10))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        Text(item.sourcePlatform ?? (item.typeRaw == "验证码" ? "短信" : "未知"))
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    Divider()

                    // 取件码
                    VStack(alignment: .leading, spacing: 4) {
                        Text("取件码")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.content)
                            .font(.system(size: 40, weight: .heavy))
                    }

                    // 详细信息列表
                    VStack(spacing: 16) {
                        detailRow(icon: "box.truck", label: "快递公司", value: item.sourcePlatform ?? (item.typeRaw == "验证码" ? "短信" : "未知"))
                        if let name = item.stationName {
                            detailRow(icon: "building.2", label: "驿站名称", value: name)
                        }
                        if let addr = item.stationAddress {
                            detailRow(icon: "mappin.and.ellipse", label: "详细地址", value: addr)
                        }
                        detailRow(icon: "clock", label: "时间", value: item.createdAt.formatted(.dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

            // 原始短信卡片
            if let original = item.originalContent, !original.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("原始短信", systemImage: "doc.text")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(original)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            UIPasteboard.general.string = original
                        }
                }
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
}
