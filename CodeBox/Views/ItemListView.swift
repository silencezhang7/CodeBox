import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipboardItem]
    @State private var showingAddSheet = false
    @State private var showingQuickMarkBanner = true

    let filterType: ItemType

    init(filterType: ItemType) {
        self.filterType = filterType
        let filterValue = filterType.rawValue
        _items = Query(filter: #Predicate<ClipboardItem> { item in
            item.typeRaw == filterValue
        }, sort: \ClipboardItem.createdAt, order: .reverse)
    }

    var pendingItems: [ClipboardItem] {
        items.filter { !$0.isUsed }
    }

    var completedItems: [ClipboardItem] {
        items.filter { $0.isUsed }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. 顶部数据看板
                    HStack(spacing: 16) {
                        // 待取卡片
                        DashboardCard(
                            title: "待取",
                            icon: "shippingbox.circle.fill",
                            iconColor: .orange,
                            count: pendingItems.count
                        )
                        
                        // 已取卡片
                        DashboardCard(
                            title: "本月已取",
                            icon: "checkmark.square.fill",
                            iconColor: .green,
                            count: completedItems.count,
                            showArrow: true
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 2. 待取件区域
                    if !pendingItems.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("待取件 (\(pendingItems.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            
                            ForEach(pendingItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    ItemRowView(item: item)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 3. 快速标记已取提示横幅
                    if showingQuickMarkBanner {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("快速标记已取")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("点击待取件卡片即可快速标记为已取")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation { showingQuickMarkBanner = false }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    
                    // 4. 已取件区域 (所有取件码)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("所有取件码")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 16)
                        
                        if completedItems.isEmpty {
                            Text("暂无已取件数据")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(completedItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    ItemRowView(item: item)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(filterType.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddClipboardItemView(defaultType: filterType)
            }
        }
    }
}

// 顶部数据看板组件
struct DashboardCard: View {
    var title: String
    var icon: String
    var iconColor: Color
    var count: Int
    var showArrow: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if showArrow {
                    Image(systemName: "arrow.right.arrow.left")
                        .foregroundColor(.secondary)
                        .font(.system(size: 10))
                }
            }
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
