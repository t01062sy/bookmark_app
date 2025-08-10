import Foundation
import SwiftData
import SwiftUI

@Model
final class Bookmark {
    var id: String
    var remoteId: String? // Supabase側のUUID
    var url: String
    var canonicalUrl: String?
    var domain: String
    var sourceType: SourceType
    var titleRaw: String?
    var title: String // titleFinal から title に簡素化
    var summary: String
    var tags: [String]
    var category: BookmarkCategory
    var contentText: String?
    var createdAt: Date
    var updatedAt: Date
    var readAt: Date?
    var isRead: Bool // computed property から stored property に変更
    var isPinned: Bool // pinned から isPinned に変更
    var isArchived: Bool // archived から isArchived に変更
    var llmStatus: LLMStatus
    
    init(
        url: String,
        title: String,
        summary: String = "",
        category: BookmarkCategory = .other,
        sourceType: SourceType = .other,
        tags: [String] = [],
        isRead: Bool = false,
        isPinned: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID().uuidString
        self.remoteId = nil
        self.url = url
        self.canonicalUrl = nil
        self.domain = URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? "unknown"
        self.sourceType = sourceType
        self.titleRaw = nil
        self.title = title
        self.summary = summary
        self.tags = tags
        self.category = category
        self.contentText = nil
        self.createdAt = createdAt
        self.updatedAt = Date()
        self.readAt = isRead ? Date() : nil
        self.isRead = isRead
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.llmStatus = .queued
    }
}

// MARK: - Enums

enum SourceType: String, CaseIterable, Codable {
    case youtube = "youtube"
    case x = "x"
    case article = "article"
    case news = "news"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .x: return "X (Twitter)"
        case .article: return "記事"
        case .news: return "ニュース"
        case .other: return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .x: return "bubble.left.and.bubble.right"
        case .article: return "doc.text"
        case .news: return "newspaper"
        case .other: return "link"
        }
    }
}

enum BookmarkCategory: String, CaseIterable, Codable {
    case tech = "tech"
    case news = "news"
    case blog = "blog"
    case video = "video"
    case social = "social"
    case academic = "academic"
    case product = "product"
    case entertainment = "entertainment"
    case lifestyle = "lifestyle"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .tech: return "技術記事"
        case .news: return "ニュース"
        case .blog: return "ブログ"
        case .video: return "動画"
        case .social: return "ソーシャル"
        case .academic: return "学術論文"
        case .product: return "商品・サービス"
        case .entertainment: return "エンターテインメント"
        case .lifestyle: return "ライフスタイル"
        case .other: return "その他"
        }
    }
    
    var color: Color {
        switch self {
        case .tech: return .blue
        case .news: return .red
        case .blog: return .green
        case .video: return .purple
        case .social: return .orange
        case .academic: return .indigo
        case .product: return .yellow
        case .entertainment: return .pink
        case .lifestyle: return .mint
        case .other: return .gray
        }
    }
}

enum LLMStatus: String, CaseIterable, Codable {
    case queued = "queued"
    case processing = "processing"
    case done = "done"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .queued: return "処理待ち"
        case .processing: return "処理中"
        case .done: return "完了"
        case .failed: return "失敗"
        }
    }
    
    var icon: String {
        switch self {
        case .queued: return "clock"
        case .processing: return "gear"
        case .done: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
}