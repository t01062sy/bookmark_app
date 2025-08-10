import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    @State private var searchText = ""
    @State private var selectedSourceType: SourceType? = nil
    @State private var selectedCategory: BookmarkCategory? = nil
    @State private var showingAddBookmark = false
    
    // API Client and Sync Service - Temporarily disabled for build
    // @StateObject private var apiClient = BookmarkAPIClient()
    // @State private var syncService: BookmarkSyncService?
    @State private var isSyncing = false
    @State private var syncError: String?
    
    private var filteredBookmarks: [Bookmark] {
        var result = bookmarks.filter { !$0.isArchived }
        
        // 検索テキストでフィルタ
        if !searchText.isEmpty {
            result = result.filter { bookmark in
                bookmark.title.localizedCaseInsensitiveContains(searchText) ||
                bookmark.summary.localizedCaseInsensitiveContains(searchText) ||
                bookmark.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // ソースタイプでフィルタ
        if let selectedSourceType {
            result = result.filter { $0.sourceType == selectedSourceType }
        }
        
        // カテゴリでフィルタ
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // ピン留めを上位、その後は作成日時順
        return result.sorted { bookmark1, bookmark2 in
            if bookmark1.isPinned != bookmark2.isPinned {
                return bookmark1.isPinned && !bookmark2.isPinned
            }
            return bookmark1.createdAt > bookmark2.createdAt
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // フィルタセクション
                filterSection
                
                // ブックマーク一覧
                if filteredBookmarks.isEmpty {
                    emptyStateView
                } else {
                    bookmarkList
                }
            }
            .navigationTitle("ブックマーク")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: syncFromRemote) {
                        HStack(spacing: 4) {
                            Image(systemName: isSyncing ? "arrow.trianglehead.2.clockwise" : "arrow.clockwise")
                            if isSyncing {
                                Text("同期中")
                                    .font(.caption)
                            }
                        }
                    }
                    .disabled(isSyncing)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddBookmark = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBookmark) {
                AddBookmarkView()
            }
        }
        .onAppear {
            // setupApiIntegration() // Temporarily disabled
            setupSampleDataIfNeeded()
        }
    }
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("検索", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // フィルタチップス
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // ソースタイプフィルタ
                    ForEach(SourceType.allCases, id: \.self) { sourceType in
                        FilterChip(
                            title: sourceType.displayName,
                            icon: sourceType.icon,
                            isSelected: selectedSourceType == sourceType
                        ) {
                            selectedSourceType = selectedSourceType == sourceType ? nil : sourceType
                        }
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // カテゴリフィルタ
                    ForEach([BookmarkCategory.tech, .news, .video, .blog], id: \.self) { category in
                        FilterChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var bookmarkList: some View {
        List {
            ForEach(filteredBookmarks) { bookmark in
                NavigationLink(destination: BookmarkDetailView(bookmark: bookmark)) {
                    BookmarkRowView(bookmark: bookmark)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteBookmarks)
        }
        .listStyle(.plain)
        .refreshable {
            await syncFromRemoteAsync()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("ブックマークがありません")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("新しいブックマークを追加してみましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddBookmark = true }) {
                Label("ブックマークを追加", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteBookmarks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let bookmark = filteredBookmarks[index]
                bookmark.isArchived = true
                bookmark.updatedAt = Date()
            }
        }
    }
    
    private func setupSampleDataIfNeeded() {
        // 既にデータがある場合はスキップ
        if !bookmarks.isEmpty { return }
        
        // サンプルデータを追加
        for sampleBookmark in SampleData.bookmarks {
            let bookmark = sampleBookmark.toBookmark()
            modelContext.insert(bookmark)
        }
        
        try? modelContext.save()
    }
    
    private func setupApiIntegration() {
        // API integration temporarily disabled for build
        // syncService = BookmarkSyncService(apiClient: apiClient, modelContext: modelContext)
        
        // // 自動同期をバックグラウンドで実行
        // Task {
        //     await syncService?.backgroundSync()
        // }
    }
    
    private func syncFromRemote() {
        // Temporarily disabled for build
        // guard let syncService = syncService else { return }
        
        // Task {
        //     do {
        //         try await syncService.syncFromRemote()
        //     } catch {
        //         print("Sync error: \(error.localizedDescription)")
        //     }
        // }
        
        // Simulate sync for UI testing
        isSyncing = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            isSyncing = false
        }
    }
    
    private func syncFromRemoteAsync() async {
        // Temporarily disabled for build
        // guard let syncService = syncService else { return }
        
        // do {
        //     try await syncService.syncFromRemote()
        // } catch {
        //     print("Sync error: \(error.localizedDescription)")
        // }
        
        // Simulate sync for UI testing
        isSyncing = true
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        isSyncing = false
    }
}

// MARK: - サブビュー

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct BookmarkRowView: View {
    let bookmark: Bookmark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー行
            HStack {
                // ソースタイプアイコン
                Image(systemName: bookmark.sourceType.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(bookmark.domain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // LLMステータス
                HStack(spacing: 4) {
                    Image(systemName: bookmark.llmStatus.icon)
                        .font(.caption2)
                    Text(bookmark.llmStatus.displayName)
                        .font(.caption2)
                }
                .foregroundColor(bookmark.llmStatus == .failed ? .red : .secondary)
            }
            
            // タイトル
            HStack {
                Text(bookmark.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if bookmark.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // 要約
            if !bookmark.summary.isEmpty {
                Text(bookmark.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // タグとカテゴリ
            HStack {
                // カテゴリ
                Text(bookmark.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(bookmark.category.color.opacity(0.2))
                    .foregroundColor(bookmark.category.color)
                    .cornerRadius(6)
                
                // タグ（最初の2つまで）
                ForEach(Array(bookmark.tags.prefix(2)), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if bookmark.tags.count > 2 {
                    Text("+\(bookmark.tags.count - 2)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 作成日時
                Text(bookmark.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Bookmark.self, inMemory: true)
}