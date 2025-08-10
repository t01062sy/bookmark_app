import Foundation
import SwiftData

/// ローカル Swift Data と Supabase API 間のデータ同期を管理
/// Phase 1B Week 3: データ同期機能実装
@MainActor
class BookmarkSyncService: ObservableObject {
    
    private let apiClient: BookmarkAPIClient
    private let modelContext: ModelContext
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init(apiClient: BookmarkAPIClient, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
    
    // MARK: - Bookmark Creation (Local + Remote)
    
    /// 新しいブックマークを作成（ローカル保存 + API同期）
    func createBookmark(url: String, title: String? = nil) async throws -> Bookmark {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            // API経由で保存
            let request = CreateBookmarkRequest(
                url: url,
                title: title,
                tags: nil,
                category: nil,
                sourceType: nil
            )
            
            let response = try await apiClient.createBookmark(request)
            
            // レスポンスをSwift Dataモデルに変換
            let bookmark = convertResponseToBookmark(response)
            
            // ローカルデータベースに保存
            modelContext.insert(bookmark)
            try modelContext.save()
            
            return bookmark
            
        } catch {
            syncError = "Failed to create bookmark: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Data Synchronization
    
    /// リモートからローカルへの完全同期
    func syncFromRemote() async throws {
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
        }
        
        do {
            // リモートから全ブックマークを取得
            let request = GetBookmarksRequest(limit: 100) // 最初は100件まで
            let response = try await apiClient.getBookmarks(request)
            
            // ローカルの既存データを取得
            let fetchDescriptor = FetchDescriptor<Bookmark>()
            let localBookmarks = try modelContext.fetch(fetchDescriptor)
            let localBookmarkIds = Set(localBookmarks.compactMap { $0.remoteId })
            
            // リモートデータをローカルに同期
            for remoteBookmark in response.data {
                if localBookmarkIds.contains(remoteBookmark.id) {
                    // 既存ブックマークの更新
                    if let existingBookmark = localBookmarks.first(where: { $0.remoteId == remoteBookmark.id }) {
                        updateLocalBookmark(existingBookmark, with: remoteBookmark)
                    }
                } else {
                    // 新規ブックマークの追加
                    let newBookmark = convertResponseToBookmark(remoteBookmark)
                    modelContext.insert(newBookmark)
                }
            }
            
            try modelContext.save()
            
            // 同期日時を記録
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
            
        } catch {
            syncError = "Failed to sync from remote: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// ローカルからリモートへの同期（未実装 - 今後の拡張用）
    func syncToRemote() async throws {
        // 将来実装: ローカル変更をリモートに送信
        // 現在はread-onlyでリモートが情報源
    }
    
    // MARK: - Data Conversion
    
    /// API ResponseをSwift Data Bookmarkモデルに変換
    private func convertResponseToBookmark(_ response: BookmarkResponse) -> Bookmark {
        let bookmark = Bookmark(
            url: response.url,
            title: response.titleFinal,
            summary: response.summary ?? "",
            category: BookmarkCategory(rawValue: response.category) ?? .other,
            sourceType: SourceType(rawValue: response.sourceType) ?? .other,
            tags: response.tags,
            isRead: response.readAt != nil,
            isPinned: response.pinned,
            isArchived: response.archived,
            createdAt: response.createdAt
        )
        
        // リモートIDを設定（同期用）
        bookmark.remoteId = response.id
        bookmark.domain = response.domain
        bookmark.llmStatus = LLMStatus(rawValue: response.llmStatus) ?? .queued
        
        return bookmark
    }
    
    /// 既存ローカルブックマークをリモートデータで更新
    private func updateLocalBookmark(_ local: Bookmark, with remote: BookmarkResponse) {
        // リモートのデータでローカルを更新（リモートが情報源）
        local.title = remote.titleFinal
        local.summary = remote.summary ?? ""
        local.category = BookmarkCategory(rawValue: remote.category) ?? .other
        local.sourceType = SourceType(rawValue: remote.sourceType) ?? .other
        local.tags = remote.tags
        local.isRead = remote.readAt != nil
        local.isPinned = remote.pinned
        local.isArchived = remote.archived
        local.domain = remote.domain
        local.llmStatus = LLMStatus(rawValue: remote.llmStatus) ?? .queued
        
        // 更新日時を設定
        if let updatedAt = formatDate(remote.updatedAt) {
            // 必要に応じて更新日時フィールドを追加
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    /// 自動同期の必要性をチェック
    var shouldAutoSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSync) > 300 // 5分経過
    }
    
    /// バックグラウンド同期実行
    func backgroundSync() async {
        if shouldAutoSync && !isSyncing {
            try? await syncFromRemote()
        }
    }
}