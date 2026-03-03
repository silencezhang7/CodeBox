import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipboardItem]
    @State private var showingAddSheet = false
    @State private var showingQuickMarkBanner = true
    @State private var editMode: EditMode = .inactive
    @State private var isMultiSelecting = false
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

    private var pendingDeleteAction: ((IndexSet) -> Void)? {
        return { indexSet in deleteItems(from: pendingItems, at: indexSet) }
    }
    
    private var completedDeleteAction: ((IndexSet) -> Void)? {
        return { indexSet in deleteItems(from: completedItems, at: indexSet) }
    }

    // Dynamic strings based on item type
    private var pendingTitle: String {
        filterType == .verificationCode ? "未使用" : "待取"
    }
    
    private var completedTitle: String {
        filterType == .verificationCode ? "已收取" : "本月已取"
    }
    
    private var pendingSectionTitle: String {
        filterType == .verificationCode ? "待使用验证码" : "待取件"
    }
    
    private var completedSectionTitle: String {
        filterType == .verificationCode ? "已收取验证码" : "已取件"
    }
    
    private var quickMarkTitle: String {
        filterType == .verificationCode ? "快速标记已收取" : "快速标记已取"
    }
    
    private var quickMarkDesc: String {
        filterType == .verificationCode ? "点击未使用卡片即可快速标记为已收取" : "点击待取件卡片即可快速标记为已取"
    }

    var body: some View {
        NavigationStack {
            List(selection: $selectedItems) {
                // 1. 顶部数据看板
                HStack(spacing: 16) {
                    // 待取卡片
                    DashboardCard(
                        title: pendingTitle,
                        icon: "shippingbox.circle.fill",
                        iconColor: .orange,
                        count: pendingItems.count
                    )
                    
                    // 已取卡片
                    DashboardCard(
                        title: completedTitle,
                        icon: "checkmark.square.fill",
                        iconColor: .green,
                        count: completedItems.count,
                        showArrow: true
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                
                // 解决 SwiftUI 列表在没有结构变化时，进入编辑模式复选框不显示的 Bug
                if !isEditing {
                    Color.clear
                        .frame(height: 0)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }
                
                // 2. 待取件区域
                if !pendingItems.isEmpty {
                    Section {
                        ForEach(pendingItems) { item in
                            ZStack {
                                ItemRowView(item: item)
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    EmptyView()
                                }
                                .opacity(0)
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
                            .deleteDisabled(isMultiSelecting)
                        }
                        .onDelete(perform: pendingDeleteAction)
                    } header: {
                        HStack {
                            Text("\(pendingSectionTitle) (\(pendingItems.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .textCase(nil)
                            Spacer()
                            
                            if isEditing {
                                Button("删除") {
                                    deleteSelectedItems()
                                }
                                .font(.subheadline)
                                .foregroundColor(selectedItems.isEmpty ? .gray : .red)
                                .disabled(selectedItems.isEmpty)
                                .padding(.trailing, 8)
                                
                                Button("取消") {
                                    withAnimation {
                                        editMode = .inactive
                                        selectedItems.removeAll()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        isMultiSelecting = false
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            } else {
                                Button("多选") {
                                    isMultiSelecting = true
                                    withAnimation {
                                        editMode = .active
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 0)
                        .padding(.top, -10)
                    }
                }
                
                // 3. 快速标记已取提示横幅
                if showingQuickMarkBanner && !pendingItems.isEmpty && !isEditing {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quickMarkTitle)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(quickMarkDesc)
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
                            ZStack {
                                ItemRowView(item: item)
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .deleteDisabled(isMultiSelecting)
                        }
                        .onDelete(perform: completedDeleteAction)
                    } header: {
                        HStack {
                            Text("\(completedSectionTitle) (\(completedItems.count))")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .textCase(nil)
                            Spacer()
                            
                            if isEditing {
                                Button("删除") {
                                    deleteSelectedItems()
                                }
                                .font(.subheadline)
                                .foregroundColor(selectedItems.isEmpty ? .gray : .red)
                                .disabled(selectedItems.isEmpty)
                                .padding(.trailing, 8)
                                
                                Button("取消") {
                                    withAnimation {
                                        editMode = .inactive
                                        selectedItems.removeAll()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        isMultiSelecting = false
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            } else {
                                Button("多选") {
                                    isMultiSelecting = true
                                    withAnimation {
                                        editMode = .active
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
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
                if !isEditing {
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
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddSheet) {
                AddClipboardItemView(defaultType: filterType)
            }
            .sheet(item: $itemToEdit) { item in
                EditClipboardItemView(item: item)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func deleteItem(_ item: ClipboardItem) {
        withAnimation {
            ReminderManager.shared.removeReminder(for: item)
            modelContext.delete(item)
        }
    }
    
    private func deleteItems(from array: [ClipboardItem], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = array[index]
                ReminderManager.shared.removeReminder(for: item)
                modelContext.delete(item)
            }
        }
    }
    
    private func deleteSelectedItems() {
        withAnimation {
            for itemId in selectedItems {
                if let item = items.first(where: { $0.id == itemId }) {
                    ReminderManager.shared.removeReminder(for: item)
                    modelContext.delete(item)
                }
            }
            selectedItems.removeAll()
            editMode = .inactive
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isMultiSelecting = false
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
