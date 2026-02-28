import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipboardItem]
    @State private var showingAddSheet = false
    @State private var showingQuickMarkBanner = true
    @State private var editMode: EditMode = .inactive
    @State private var selectedItems = Set<UUID>()
    @State private var itemToEdit: ClipboardItem? = nil
    
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
    
    private var isEditing: Bool {
        editMode == .active
    }

    var body: some View {
        NavigationStack {
            List {
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                
                // 2. 待取件区域
                if !pendingItems.isEmpty {
                    Section {
                        ForEach(pendingItems) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemRowView(item: item)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .contextMenu {
                                Button {
                                    itemToEdit = item
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(from: pendingItems, at: indexSet)
                        }
                    } header: {
                        HStack {
                            Text("待取件 (\(pendingItems.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .textCase(nil)
                            Spacer()
                            Image(systemName: "list.bullet")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 0)
                    }
                }
                
                // 3. 快速标记已取提示横幅
                if showingQuickMarkBanner && !pendingItems.isEmpty && !isEditing {
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
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                // 4. 已取件区域
                if !completedItems.isEmpty {
                    Section {
                        ForEach(completedItems) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemRowView(item: item)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            deleteItems(from: completedItems, at: indexSet)
                        }
                    } header: {
                        HStack {
                            Text("已取件 (\(completedItems.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .textCase(nil)
                            Spacer()
                        }
                        .padding(.horizontal, 0)
                        .padding(.top, 8)
                    }
                }
                
                // 当没有数据时的空状态
                if items.isEmpty {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }
            }
            .listStyle(.plain)
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(filterType.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("完成") {
                            withAnimation {
                                editMode = .inactive
                                selectedItems.removeAll()
                            }
                        }
                    } else {
                        Menu {
                            Button(action: { showingAddSheet = true }) {
                                Label("添加", systemImage: "plus")
                            }
                            if !items.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        editMode = .active
                                    }
                                }) {
                                    Label("批量删除", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
                
                if isEditing && !selectedItems.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            deleteSelectedItems()
                        } label: {
                            Text("删除 (\(selectedItems.count))")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddSheet) {
                AddClipboardItemView(defaultType: filterType)
            }
            .sheet(item: $itemToEdit) { item in
                // TODO: Replace with an actual edit view
                // For now reusing the add view with modified logic or just passing the item
                AddClipboardItemView(defaultType: filterType) 
            }
        }
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            modelContext.delete(item)
        }
    }
    
    private func deleteItems(from array: [ClipboardItem], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(array[index])
            }
        }
    }
    
    private func deleteSelectedItems() {
        withAnimation {
            for itemId in selectedItems {
                if let item = items.first(where: { $0.id == itemId }) {
                    modelContext.delete(item)
                }
            }
            selectedItems.removeAll()
            editMode = .inactive
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
