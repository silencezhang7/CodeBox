import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ClipboardItem]
    @State private var showingAddSheet = false

    let filterType: ItemType

    init(filterType: ItemType) {
        self.filterType = filterType
        let filterValue = filterType.rawValue
        _items = Query(filter: #Predicate<ClipboardItem> { item in
            item.typeRaw == filterValue
        }, sort: \ClipboardItem.createdAt, order: .reverse)
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ZStack {
                        Color(uiColor: .secondarySystemBackground)
                            .ignoresSafeArea()
                        VStack {
                            Image(systemName: filterType == .pickupCode ? "shippingbox" : "lock.shield")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.bottom, 10)
                            Text("暂无\(filterType.rawValue)数据")
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    List {
                        ForEach(items) { item in
                            ItemRowView(item: item)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            for index in indexSet { modelContext.delete(items[index]) }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(filterType.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddClipboardItemView(defaultType: filterType)
            }
        }
    }
}
